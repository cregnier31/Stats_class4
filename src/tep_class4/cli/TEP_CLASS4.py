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
             June 2025    : Cleanup the code

Developer:
    C. REGNIER
"""
import sys
from os.path import dirname
import resource
from timeit import default_timer as timer

# Import local modules
from tep_class4.core.Selector import Selector
from tep_class4.core.Loader import Loader
from tep_class4.core.Interpolator import Interpolator
from tep_class4.core.Writer import Writer
from tep_class4.core.utils import create_dict
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
    log.debug('========================================================')
    log.debug('          Load input options and parameter file         ')
    log.debug('========================================================')
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
    log.debug(f'Keys {list_keys}')
    unique_leadtime = sorted({key.split('-')[1] for key in list_keys['keyvalues']})
    unique_leadtime_unit = sorted({int(key.split('-')[2]) for key in list_keys['keyvalues']})
    log.debug(f'{unique_leadtime=}')
    log.debug(f'{unique_leadtime_unit=}')
    for keyvalue in list_keys['keyvalues']:
        dateval, leadtime, lead_int = keyvalue.split('-')
        start = timer()
        log.info(f'Interp day {dateval} {leadtime} leadtime {lead_int}')
        log.info('========================================================')
        # Selection of the input data
        log.info(f"Selection of input data {param_dict['data_format']} {param_dict['data_type']}")
        log.info('========================================================')
        input_list_files, ll_miss = Selector(param_dict['data_format'], param_dict['data_type'], log).\
            factory("GLOBAL_INPUT_DATA").run(param_dict, dateval)
        if ll_miss:
            log.info(f'File is missing for the observation {dateval}')
            continue
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
                    log.info(f'Intermediate file exist {file}')
                    continue
                #if not read_outputnp(file_out):
                tab_results, file_out = Interpolator(log, dask=param_dict['dask']).read_and_interp(
                    file, param_dict, date=dateval, leadtime=leadtime, lead_int=lead_int)
                # Write output file
                log.info("========================================================")
                log.info(f'Write interp file for day {dateval} {file_out}')
                log.info("========================================================")
                log.debug(tab_results.keys())
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
