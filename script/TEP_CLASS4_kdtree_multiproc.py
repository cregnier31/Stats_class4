#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
""" Description :
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
    Developer  : C.REGNIER
"""
#
from __future__ import generators
import os
import sys
import numpy as np
from os.path import dirname
sys.path.append(dirname(__file__)+'/../modules/')
import resource
# Import local modules
from Selector import Selector
from Loader import Loader
from Interpolator import Interpolator
from Writer import Writer
from mpi4py import MPI
import pickle
from utils import create_dict
# Set Stack to unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY,
                                           resource.RLIM_INFINITY))


def main(level=2):
    """
    Main TEP CLASS4 function
    """

    # ==================================================================
    #  PART-1 -  Load input parameters
    # ==================================================================
    param_dict, log = Loader().factory('INPUT').load(sys.argv[1:], level)
    log.info('========================================================')
    log.info('          Load input options and parameter file         ')
    log.info('========================================================')
    # Load db configuration file
    conf_path = dirname(__file__) #os.getcwd()
    filename = conf_path + '/cfg/' + param_dict['confname']
    param_dict = Loader.factory('NML').load(filename, level, param_dict, log)
    # ==========================================================================
    # PART-2 - Loop for a given time range
    # ==========================================================================
    log.info('========================================================')
    log.info('              Launch time loop                          ')
    log.info('========================================================')
    ## Create dictionnary
    list_keys = create_dict(param_dict['date1'],
                            param_dict['date2'],
                            param_dict['lead_time'],
                            param_dict['lead_int'])

    # *********** MPI section to split dates on each processor ***********
    comm = MPI.COMM_WORLD
    ndate = len(list_keys['keyvalues'])
    if comm.rank == 0:
        log.info(f"Number of date {ndate}")
        log.info(f"Size of the comm {comm.size}")
    irest  = np.mod(ndate,comm.size)
    ntask  = ndate // comm.size
    log.debug(f'Number of tasks {ntask}')
    log.debug(f"irest = {irest}")
    istart = int(ntask*comm.rank)
    iend   = int(istart + ntask - 1)
    log.debug(f"Start {istart} End {iend}")
    cla_date = np.array(list_keys['keyvalues'][istart:iend+1]).tolist()
    iend_tot = ntask*comm.size-1
    log.debug(f"iend_tot = {iend_tot}")
    if irest > 0 and comm.rank < irest:
        cla_date.append(list_keys['keyvalues'][iend_tot+comm.rank+1])
    log.debug(f'Date to run {cla_date}')
    for keyvalue in cla_date:
        dateval, leadtime, lead_int = keyvalue.split('-')
        # Selection of the input data
        if comm.rank == 0:
            log.info(f'Selection of input data for {dateval}')
            log.info('========================================================')
        input_list_files, ll_miss = Selector(param_dict['data_format'], param_dict['data_type'], log).\
            factory("GLOBAL_INPUT_DATA").run(param_dict, dateval)
        if ll_miss:
            continue
        if not ll_miss:
            # Interpolation of the data
            for file in input_list_files:
                tab_results, file_out = Interpolator(log, dask=param_dict['dask']).read_and_interp(
                     file, param_dict, date=dateval, leadtime=leadtime, lead_int=lead_int)
                # Write output file
                if comm.rank == 0:
                    log.info("========================================================")
                    log.info(f'Write interp file for day {dateval} {file_out}')
                    log.info("========================================================")
                Writer(log).write_outputnp(file_out,
                                           tab_results,
                                           param_dict,
                                           dateval,
                                           leadtime,
                                           lead_int)
    comm.Barrier()
    ## Recombine output files
    if comm.rank == 0:
        log.info(f'Recombine files')
        Writer(log).write_class4_out(param_dict, list_keys)
        log.info(f'End of the code')
# Set the level of logger
#log_level = 1
# Run the main code
main()
