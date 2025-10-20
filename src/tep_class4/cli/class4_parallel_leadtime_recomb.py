#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
"""
===========================================================================
TEP CLASS4 Parallel Observation Interpolation
===========================================================================

Description:
    This script reads observation files and interpolates them on model grids
    for a given date range. Parallelization is applied in a memory-efficient
    way:
        - Outer level: parallelization over observations (loky processes)
        - Inner level: parallelization over leadtimes (threading)

    Heavy objects like interpolator and grids are shared in threads to avoid
    memory duplication.

Usage:
    python class4_parallel_leadtime.py --config=CONFIG_NAME --date1=YYYYMMDD \
        --date2=YYYYMMDD --typemod=MODEL_TYPE --data=DATA_TYPE [--all] --max_nodes=X

Arguments:
    --config     Name of configuration
    --date1      Start date (YYYYMMDD)
    --date2      End date (YYYYMMDD)
    --data       Type of data to process
    --typemod    Model type (e.g., 'pgn')
    --all        Flag to process all types (hindcast + forecast + persistence)
    --max_nodes  Maximum of nodes factor for job paralllelisation

Author:
    Charly REGNIER

Date:
    2025-09-02

===========================================================================
"""

import sys
from os.path import dirname
import resource
from timeit import default_timer as timer
import argparse
import numpy as np
from joblib import Parallel, delayed, cpu_count

# Import local modules
from tep_class4.core.Extractor import Extractor
from tep_class4.core.Loader import Loader
from tep_class4.core.Interpolator import Interpolator
from tep_class4.core.Logger import Logger
from tep_class4.core.Writer import Writer
from tep_class4.core.utils import create_dict, create_listdate, create_leadtime, get_nodes
from tep_class4.core.inputdata_loader import inputdata_loader, read_observations
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY,
                                           resource.RLIM_INFINITY))
# -----------------------------
# Helper function for one leadtime
# -----------------------------
def process_leadtime(interpolator, file_obs, tuple_obs, weight, indexes,
                     param_dict, obs_data, dateval, keyvalue, log, inner_threads=1):
    log_proc = Logger(f"TEP_CLASS4_{dateval}").run(param_dict['loglevel'])
    # Rebuild a logger for this worker
    leadtime, lead_int = keyvalue.split('-')
    log_proc.debug(f'get_modelvalue {leadtime} {lead_int}')
    log_proc.info(f'Process leadtime {leadtime} {lead_int}')
    dict_var_in = interpolator.get_modelvalue(param_dict, dateval, leadtime,
                                              lead_int,log=log_proc)
    start = timer()
    log_proc.debug(f'Work on multiprocess leadtime {leadtime} length {lead_int} Days')

    # Skip if output already exists
    if Writer(log_proc).test_output(file_obs, param_dict, dateval, leadtime, lead_int):
        log_proc.info(f'Intermediate file exists for {file_obs} leadtime {leadtime}')
        return None

    # Interpolation
    tab_results, file_out = interpolator.read_and_interp(
        file_obs,
        tuple_obs,
        weight,
        indexes,
        param_dict,
        obs_data,
        dict_var_in,
        date=dateval,
        leadtime=leadtime,
        lead_int=lead_int,
        inner_threads=inner_threads
    )
    # Write output
    log_proc.debug(f'Write interp file for day {dateval} {file_out}')
    Writer(log_proc).write_outputnp(file_out, tab_results, param_dict,
                               dateval, leadtime, lead_int)
    end = timer()
    log_proc.debug(f"~~ Time elapsed to process leadtime {leadtime}: {end - start:.2f}s ~~")
    return file_out

def main(level=2):
    """
    Main TEP CLASS4 function
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--date1", required=True)
    parser.add_argument("--date2", required=True)
    parser.add_argument("--np_max", required=True)
    parser.add_argument("--np_threads", required=True)
    parser.add_argument("--data", required=True,  help="Type of data to process")
    parser.add_argument("--no-recombine", action="store_true",
        help="If set, skip file recombination (default: recombination is performed)"
    )
    parser.add_argument("--typemod", required=True)
    parser.add_argument("--loglevel", type=int, default=2)
    parser.add_argument("--fcst (only forecasts)", action="store_true")
    parser.add_argument("--best (only hindcast)", action="store_true")
    parser.add_argument("--all (hdct fcst and pers)", action="store_true")
    args = parser.parse_args()
    do_recombine = not args.no_recombine
    # ==================================================================
    #  PART-1 -  Load input parameters
    # ==================================================================
    param_dict, log = Loader().factory('INPUT').load(sys.argv[1:], level)
    log.debug('========================================================')
    log.debug('          Load input options and parameter file         ')
    log.debug('========================================================')
    # Load db configuration file
    conf_path = dirname(__file__)
    filename = conf_path + '/cfg/' + param_dict['confname']
    param_dict = Loader.factory('NML').load(filename, level, param_dict, log)
    # Create interpolator and read grid file
    interpolator = Interpolator(log, dask=param_dict['dask'])
    interpolator.get_grid_coords(param_dict, log)
    # ==========================================================================
    # PART-2 - Loop for a given time range
    # ==========================================================================
    log.info('========================================================')
    #log.info('              Launch variable/time loop                          ')
    #log.info('========================================================')
    # Create liste date
    list_date = create_listdate(param_dict['date1'],param_dict['date2'])
    for selected_var in param_dict['list_variables']:
        # Create dictionnary
        list_leadtime = create_leadtime(
                                        param_dict,
                                        selected_var,
                                        )
        start = timer()
        log.debug(f'{list_leadtime}')
        param_dict['prefix_data'] = param_dict['prefix_data_all'][selected_var]
        param_dict['data_format'] = param_dict['data_format_all'][selected_var]
        param_dict['data_type'] = selected_var
        param_dict['dirdata'] = param_dict['dirdata_all'][selected_var]
        param_dict['varname'] = param_dict['varname_all'][selected_var]
        param_dict['cl_src'] = param_dict['typedata_all'][selected_var]
        log.info(
            f"Work on selected variable {selected_var} {param_dict['data_type']}"
            )
        for dateval in list_date:
            log.info(f'Work on day {dateval}')
            # Find observations for a given day
            input_list_files = Extractor(log).factory(param_dict['prefix_data']).\
                                                      run_list(param_dict, dateval)
            if not input_list_files:
                log.error(f'Files are missing for the observation {dateval}')
                continue
            else:
                log.debug(f'List of observations {dateval} {input_list_files}')
            for file_obs in input_list_files:
                # Read obs file
                obs_data, tuple_obs = read_observations(file_obs, param_dict, log)
                # Query_weight for each observations
                log.debug(f"Search the weights values in the grid for the observations {file_obs}")
                log.info(f'Work on observations {file_obs}')
                weight, indexes = interpolator.query_weight(obs_data, param_dict, log)
                inner_threads = int(args.np_threads)
            
                if len(list_leadtime['keyvalues']) == 1:
                    # Run directly (no parallel overhead)
                    log.debug(f"No outside parallelization only 1 leadtime")
                    results = [
                        process_leadtime(
                            interpolator,
                            file_obs,
                            tuple_obs,
                            weight,
                            indexes,
                            param_dict,
                            obs_data,
                            dateval,
                            list_leadtime['keyvalues'][0],
                            log,
                            inner_threads=inner_threads
                        )
                    ]
                else:
                    # -----------------------------
                    # Parallel leadtime processing
                    # -----------------------------
                    outer_procs = int(args.np_max) #int(len(list_leadtime['keyvalues'])/2)
                    log.debug(f"Starting parallel execution {outer_procs=}{inner_threads=}")
 
                    # Launch leadtimes in parallel
                    results = Parallel(n_jobs=outer_procs, backend='loky', verbose=1)(
                        delayed(process_leadtime)(
                            interpolator,
                            file_obs,
                            tuple_obs,
                            weight,
                            indexes,
                            param_dict,
                            obs_data,
                            dateval,
                            keyvalue,
                            log,
                            inner_threads=inner_threads
                        )
                        for keyvalue in list_leadtime['keyvalues']
                    )
                    
                    # Filter out skipped leadtimes
                    results = [r for r in results if r is not None]

            log.info("=================================================")
        if do_recombine: 
            # Write output file
            log.info(f'Write output file {selected_var} {dateval}')
            Writer(log).write_class4_out(param_dict, list_leadtime, list_date)
        else: 
            log.info('Recombine not ok')

# Set the level of logger (log_level = 2)
# Run the main code
if __name__ == "__main__":
    main()
