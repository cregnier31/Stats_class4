#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
"""
Description:
    New CLASS4 launcher to compute CLASS4 with CLASS4 coming from GODAE,
    ARMOR, CORIOLIS, different ASCII files
    History: Juillet 2014  : Creation C.REGNIER
             Novembre 2014 :  Ajout différentes échéances pour l'interpolation+
             clims + gestion enchaînement des runs
             Decembre 2014 :  MAJ pour le cas particulier du zoom
             November 2016 :  New version with KDtree method for coloc and interp
             November/Dec 2017 :  Add modules in a generic lib for CLASS4
             portability Generic KDtree for SLA,SST,SSS
             September 2018 :  Add interpolator for 2D variables
             September 2018 : Refactoring
             Juillet 2020 : Add 3D insitu profiles 
             June 2025    : Cleanup the code

Developer:
    C. REGNIER
"""
import sys
import re
from os.path import dirname
import resource
from timeit import default_timer as timer
import argparse
import numpy as np

# Import local modules
#from tep_class4.core.Selector import Selector
from tep_class4.core.Extractor import Extractor
from tep_class4.core.Loader import Loader
from tep_class4.core.Interpolator import Interpolator
from tep_class4.core.Writer import Writer
from tep_class4.core.utils import create_dict, create_listdate, create_leadtime
from tep_class4.core.inputdata_loader import inputdata_loader, read_observations
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY,
                                           resource.RLIM_INFINITY))


def main(level=2):
    """
    Main TEP CLASS4 function
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    parser.add_argument("--date1", required=True)
    parser.add_argument("--date2", required=True)
    #parser.add_argument("--src", required=True)
    parser.add_argument("--data", required=True,  help="Type of data to process")
    parser.add_argument("--typemod", required=True)
    parser.add_argument("--no-recombine", action="store_true",
        help="If set, skip file recombination (default: recombination is performed)")
    parser.add_argument("--loglevel", type=int, default=2)
    parser.add_argument("--fcst (only forecasts)", action="store_true")
    parser.add_argument("--hdct (only hindcast)", action="store_true")
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
    log.info('              Launch variable/time loop                          ')
    log.info('========================================================')
    # Create liste date
    list_date = create_listdate(param_dict['date1'],param_dict['date2'])
    # Create dictionnary
    #list_leadtime = create_leadtime(
    #                            param_dict['lead_time'],
    #                            param_dict['lead_int'])
    for selected_var in param_dict['list_variables']:
        list_leadtime = create_leadtime(
                                        param_dict,
                                        selected_var,
                                        )
        log.info(f'{list_leadtime}')
        param_dict['prefix_data'] = param_dict['prefix_data_all'][selected_var]
        param_dict['data_format'] = param_dict['data_format_all'][selected_var]
        param_dict['data_type'] = selected_var
        param_dict['dirdata'] = param_dict['dirdata_all'][selected_var]
        param_dict['varname'] = param_dict['varname_all'][selected_var]
        param_dict['cl_src'] = param_dict['typedata_all'][selected_var]
        #print('prefix_data cl_src data_format data_type')
        #print(param_dict['prefix_data'])
        #print(param_dict['cl_src'])
        #print(param_dict['data_format'])
        #print(param_dict['data_type'])
        log.info(
            f"Work on selected variable {param_dict['data_type']}"
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
                #print(f"{param_dict['varname']=}")
                # Query_weight for each observations
                log.debug(f"Search the weights values in the grid for the observations {file_obs}")
                log.info(f'Work on observations {file_obs}')
                weight, indexes = interpolator.query_weight(obs_data, param_dict, log)
                #print("Varname  {param_dict['varname']}")
                #print("-------------------------------")
                #print(list_leadtime['keyvalues'])
                for keyvalue in list_leadtime['keyvalues']:
                    leadtime, lead_int = keyvalue.split('-')
                    start = timer()
                    log.info(f'---------------------------------------------------')
                    log.info(f'Work on leadtime {leadtime} length {lead_int} Days')
                    # Test the exitence of the file
                    if Writer(log).test_output(file_obs,
                                               param_dict,
                                               dateval,
                                               leadtime,
                                               lead_int):
                        filename_tmp = re.sub(r'\.nc$', f'_{dateval}_{leadtime}_{lead_int}.p', file_obs)
                        log.info(f'Intermediate file exist {filename_tmp}')
                        continue
                    dict_var_in = interpolator.get_modelvalue(param_dict, dateval, leadtime,
                                                              lead_int,log=log)
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
                        lead_int=lead_int
                    )
                    # Write output file
                    log.debug("=================================================")
                    log.debug(f'Write interp file for day {dateval} {file_out}')
                    log.debug(tab_results.keys())
                    Writer(log).write_outputnp(file_out,
                                               tab_results,
                                               param_dict,
                                               dateval,
                                               leadtime,
                                               lead_int)
                    end = timer()
                    log.info(f"~~ Time elapsed to process leadtime {end - start}s ~~")
            log.info("=================================================")
        if do_recombine: 
            # Write output file
            log.info('Write output file')
            Writer(log).write_class4_out(param_dict, list_leadtime, list_date)
            log.info('Write ok')
        else:
            log.info('Write nok')
            

# Set the level of logger (log_level = 2)
# Run the main code
if __name__ == "__main__":
    main()
