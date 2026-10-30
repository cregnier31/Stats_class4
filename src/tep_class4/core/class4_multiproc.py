#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
"""
Description:
    New CLASS4 launcher to compute CLASS4 with CLASS4 coming from GODAE,
    ARMOR, CORIOLIS, different ASCII files

History:
    July 2014       : Creation - C. REGNIER
    November 2014   : Add multiple forecast lead times for interpolation,
                      clims, and run chaining
    December 2014   : Update for zoomed region case
    November 2016   : New version with KDTree method for coloc/interp
    Nov/Dec 2017    : Modular refactor for CLASS4 portability (SLA, SST, SSS)
    September 2018  : Add interpolator for 2D variables, refactoring
    July 2020       : Add 3D in-situ profiles
    April 2025      : Edito version

Developer:
    C. REGNIER
"""

from __future__ import generators

import os
import sys
from os.path import dirname
import numpy as np
import argparse

import resource

# Import local modules
from tep_class4.core.Selector import Selector
from tep_class4.core.Loader import Loader
from tep_class4.core.Interpolator import Interpolator
from tep_class4.core.Writer import Writer
from tep_class4.core.utils import create_dict
# Set Stack to unlimited
from mpi4py import MPI
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
    parser.add_argument("--src", required=True)
    parser.add_argument("--data", required=True)
    parser.add_argument("--typemod", required=True)
    parser.add_argument("--loglevel", type=int, default=2)
    parser.add_argument("--fcst (only forecasts)", action="store_true")
    parser.add_argument("--hdct (only hindcast)", action="store_true")
    parser.add_argument("--all (hdct fcst and pers)", action="store_true")
    args = parser.parse_args()

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
    # Create dictionnary
    list_keys = create_dict(param_dict['date1'],
                            param_dict['date2'],
                            param_dict['lead_time'],
                            param_dict['lead_int'])
    # *********** MPI section to split dates on each processor ***********
    comm = MPI.COMM_WORLD
    ndate = len(list_keys['keyvalues'])
    irest = np.mod(ndate, comm.size)
    ntask = ndate//comm.size
    istart = int(ntask*comm.rank)
    iend = int(istart+ntask-1)
    cla_date = np.array(list_keys['keyvalues'][istart:iend+1]).tolist()
    iend_tot = ntask*comm.size-1
    if irest > 0 and comm.rank < irest:
        cla_date.append(list_keys['keyvalues'][iend_tot+comm.rank+1])
    # ==================================================================
    # PART-2 - Loop for a given time range
    # ==================================================================
    if comm.rank == 0:
        log.debug('====================================================')
        log.debug('              Launch time loop                          ')
        log.debug('========================================================')
        log.info(f"Number of date {ndate}")
        log.debug(f'Date to run {cla_date}')
        log.debug(f"Size of the comm {comm.size}")
        log.debug(f'Number of tasks {ntask}')
        log.debug(f"irest = {irest}")
        log.debug(f"Start {istart} End {iend}")
        log.debug(f"iend_tot = {iend_tot}")
    for keyvalue in cla_date:
        dateval, leadtime, lead_int = keyvalue.split('-')
        # Selection of the input data
        if comm.rank == 0:
            log.info(f'Selection of input data for {dateval}')
            log.info('====================================================')
        selector = Selector(
            param_dict['data_format'],
            param_dict['data_type'],
            log
        )
        global_input = selector.factory("GLOBAL_INPUT_DATA")
        input_list_files, ll_miss = global_input.run(param_dict, dateval)
        if ll_miss:
            if comm.rank == 0:
                log.info(f'File is missing for the observation {dateval}')
            continue
        if comm.rank == 0:
            log.debug(f'{input_list_files}')
        if not ll_miss:
            # Interpolation of the data
            for file in input_list_files:
                # Test existing files
                if Writer(log).test_output(file,
                                           param_dict,
                                           dateval,
                                           leadtime,
                                           lead_int):
                    if comm.rank == 0:
                        log.debug('Intermediate file exist')
                    continue
                interpolator = Interpolator(log, dask=param_dict['dask'])
                tab_results, file_out = interpolator.read_and_interp(
                    file,
                    param_dict,
                    date=dateval,
                    leadtime=leadtime,
                    lead_int=lead_int
                )
                # Write output file
                if comm.rank == 0:
                    log.info("===============================================")
                    log.info(f'Write interp file for day {dateval} {file_out}')
                    log.info("===============================================")
                Writer(log).write_outputnp(file_out,
                                           tab_results,
                                           param_dict,
                                           dateval,
                                           leadtime,
                                           lead_int)
    comm.Barrier()
    # Recombine output files
    if comm.rank == 0:
        log.info('Recombine files')
        Writer(log).write_class4_out(param_dict, list_keys)
        log.info(f"End of code {param_dict['date1']} {param_dict['date2']}")


# Run the main code
if __name__ == "__main__":
    main()
