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
             Juillet 2020 : Add 3D insitu profiles 
    Developer  : C.REGNIER
"""
#
from __future__ import generators
import os
import sys
from os.path import dirname
sys.path.append(dirname(__file__)+'/../modules/')
import resource
# Import local modules
from Selector import Selector
from Loader import Loader
from Interpolator import Interpolator
from Writer import Writer
from timeit import default_timer as timer
from utils import create_dict
from glob import glob
import numpy as np
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
    param_dict,log = Loader().factory('INPUT').load(sys.argv[1:], level)
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
    valeurj = param_dict['date1']
    ## Create dictionnary
    list_keys = create_dict(param_dict['date1'],
                            param_dict['date2'],
                            param_dict['lead_time'],
                            param_dict['lead_int'])
    unique_dates = sorted({int(key.split('-')[0]) for key in list_keys['keyvalues']})
    unique_leadtime = sorted({key.split('-')[1] for key in list_keys['keyvalues']})
    unique_leadtime_unit = sorted({int(key.split('-')[2]) for key in list_keys['keyvalues']})
    for keyvalue in list_keys['keyvalues']:
        dateval, leadtime, lead_int = keyvalue.split('-')
        start = timer()
        log.info(f'Interp day {dateval} {leadtime} leadtime {lead_int}')
        log.info('========================================================')
        # Selection of the input data
        log.info('Selection of input data')
        log.info('========================================================')
        input_list_files, ll_miss = Selector(param_dict['data_format'], param_dict['data_type'], log).\
            factory("GLOBAL_INPUT_DATA").run(param_dict, dateval)
        if ll_miss:
            log.info(f'File is missing for the observation {dateval}')
            continue
        log.info(f'{input_list_files}')
        if not ll_miss:
            # Interpolation of the data
            for file in input_list_files:
                # Test existing files
                if Writer(log).test_output(file,
                                           param_dict,
                                           dateval,
                                           leadtime,
                                           lead_int):
                    log.info('Intermediate file exist')
                    continue
                #if not read_outputnp(file_out):
                tab_results, file_out = Interpolator(log, dask=param_dict['dask']).read_and_interp(
                    file, param_dict, date=dateval, leadtime=leadtime, lead_int=lead_int)
                # Write output file
                log.info("========================================================")
                log.info(f'Write interp file for day {dateval} {file_out}')
                log.info("========================================================")
                Writer(log).write_outputnp(file_out,
                                           tab_results,
                                           param_dict,
                                           dateval,
                                           leadtime,
                                           lead_int)
        end = timer()
        log.info('~~~~~~~~ Time elapsed to process day {} : {} {}'.format
                           (str(dateval),str(end - start), " seconds ~~~~~~~~~~~~"))
    # Write output file
    log.info('Write output file')
    Writer(log).write_class4_out(param_dict, list_keys)
    log.info('End')

# Set the level of logger (log_level = 2)
# Run the main code
main()
