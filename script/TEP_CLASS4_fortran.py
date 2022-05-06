#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
# History  : July 2014  : Creation C.REGNIER
#            November 2014 :  Ajout différentes échéances pour l'interpolation + clims + gestion enchaînement des runs
#            December 2014 :  MAJ pour le cas particulier du zoom
#            December 2014 :  MAJ pour le cas particulier du zoom
#            January 2021 :  MAJ in the new version
## Description :
## New CLASS4 launcher to compute CLASS4 with CLASS4 coming from GODAE, ARMOR, CORIOLIS
#  with fortran colocation

import os,sys,string,shutil,re
import resource
from os.path import dirname
sys.path.append(dirname(__file__)+'/../modules/')
sys.path.append(dirname(__file__)+'./modules/')
from Selector import Selector
from Loader import *
from colocfortran import ColocFortran
## Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

def main(level=2):

    # =============================================================================
    #  PART-1 -  Load input parameters and file
    # =============================================================================
    param_dict,log = Loader().factory('INPUT').load(sys.argv[1:], level)
    log.info('========================================================')
    log.info('          Load input options and parameter file         ') 
    log.info('========================================================')
    log.debug("Type des fichiers d'entree {} ".format(param_dict['cl_typemod']))
    log.debug("Nombre de proc {}".format((param_dict['nb_proc'])))
    log.debug ("Daterun {}".format(param_dict['cl_daterun'] ))
    log.debug("Date1 {}".format(param_dict['date1']))
    log.debug("Date2 {}".format(param_dict['date2']))

    # ==================================
    #   Load db configuration file
    # ==================================
    conf_path = dirname(__file__) #os.getcwd()
    filename = conf_path + '/cfg/' + param_dict['confname']
    param_dict = Loader.factory('NML').load(filename, level, param_dict)

    # =============================================================================
    #  PART-2 -  DATE Selection and extraction
    # =============================================================================
    # Selection of the input data
    log.info('========================================================')
    log.info('Selection of input data')
    log.info('========================================================')
    list_files, ll_miss = Selector(param_dict['data_format'], param_dict['data_type'], log).\
            factory("GLOBAL_INPUT_DATA").run(param_dict, param_dict['cl_daterun'])

    # =============================================================================
    #  PART-3 - Compute Colocation for selected position
    # =============================================================================
    log.info('========================================================')
    log.info('              Colocation                                ')
    log.info('========================================================')
    objColoc = ColocFortran(param_dict,log)
    for fichier in list_files:
        log.info('File {}'.format(fichier))
        position, ll_file_interp  = Loader().factory("INPUT_DATA").run(param_dict, fichier, log)
        if ll_file_interp :
            log.info("Coloc file {}".format(fichier))
            objColoc.split_coloc(fichier, position)

    # =============================================================================
    # PART-4 - Compute interpolation
    # =============================================================================
    log.info('=======================================================')
    log.info('               Compute interpolation                   ')
    log.info('=======================================================')
    objColoc.interp_fortran()

    # =============================================================================
    # PART-5 - Run loop
    # =============================================================================
    if  param_dict['daymax'] : objColoc.runNext()
# Run the main code
main()
