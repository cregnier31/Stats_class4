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
from Logger import Logger
from Interpolator import Interpolator
from Writer import Writer
from mpi4py import MPI
# Set Stack to unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY,
                                           resource.RLIM_INFINITY))


def main(level=1):
    """
    Main TEP CLASS4 function
    """
    # LOGGER
    log = Logger("TEP_CLASS4").run(level)

    # ==================================================================
    #  PART-1 -  Load input parameters
    # ==================================================================
    log.info('========================================================')
    log.info('          Load input options and parameter file         ')
    log.info('========================================================')
    param_dict = Loader().factory('INPUT').load(sys.argv[1:], level, log)

    # Load db configuration file
    conf_path = dirname(__file__) #os.getcwd()
    filename = conf_path + '/cfg/' + param_dict['confname']
    param_dict = Loader.factory('NML').load(filename, level, param_dict)
    # ==========================================================================
    # PART-2 - Loop for a given time range
    # ==========================================================================
    log.info('========================================================')
    log.info('              Launch time loop                          ')
    log.info('========================================================')

    comm = MPI.COMM_WORLD
    ndate = len(param_dict['time_period'])
    irest  = np.mod(ndate,comm.size)
    ntask  = ndate / comm.size
    istart = int(ntask*comm.rank)
    iend   = int(istart + ntask - 1)
    cla_date = np.array(param_dict['time_period'][istart:iend+1]).tolist()
    iend_tot = ntask*comm.size-1
    if irest > 0 and comm.rank < irest:
        cla_date.append(param_dict['time_period'][iend_tot+comm.rank+1])

    for valeurj in cla_date:
        log.info('Interp day  %s ' % (str(valeurj)))
        dateval = str(valeurj)
        # Selection of the input data
        input_list_files, ll_miss = Selector(param_dict['data_format'], param_dict['data_type'],log).\
            factory("GLOBAL_INPUT_DATA").run(param_dict, dateval)
        log.info(input_list_files)
        if ll_miss: continue
        # Selection of the input model data
        log.info('Selection of input model')
        input_model_file,ll_miss = Selector(param_dict['data_format'], param_dict['data_type'],log).\
            factory("GLOBAL_INPUT_MODEL_DATA").run(param_dict, dateval)
        if not ll_miss:
            log.info(input_model_file)
            # Interpolation of the data
            for file in input_list_files:
                tab_results, file_out = Interpolator(log).read_and_interp(
                   file, input_model_file, param_dict, date=dateval)
                # Write output file
                log.info('Write interp file  %s ' % (str(dateval)))
                filename = param_dict['dirwork']+file_out
                Writer(log).write_output(
                   filename, tab_results, param_dict, dateval,ll_zip=param_dict['ll_zip'])
# Set the level of logger
log_level = 1
# Run the main code
main(log_level)
