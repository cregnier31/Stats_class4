#!/usr/bin/env python3
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

import os
import sys
from os.path import dirname
import resource
from timeit import default_timer as timer
import argparse
import xarray as xr
import numpy as np
import pandas as pd 
from collections import namedtuple

# Import local modules
from tep_class4.core.Selector import Selector
from tep_class4.core.Loader import Loader
from tep_class4.core.Interpolator import Interpolator
from tep_class4.core.Writer import Writer
from tep_class4.core.utils import create_dict_list
from tep_class4.core.utils import generate_nbdateslist
from tep_class4.core.inputdata_loader import inputdata_loader
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
    parser.add_argument("--zarr", action="store_true")
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
    nb_forecasts = len(param_dict['lead_int'])
    nb_leadtimes = len(param_dict['lead_time'])
    date1 = str(param_dict['date1'])
    date2 = str(param_dict['date2'])
    log.info(f"{nb_forecasts=} {nb_leadtimes=} {date1=} {date2=}")
    # Create dictionnary
    list_keys = create_dict_list(
                                date1,
                                date2,
                                param_dict['lead_time'],
                                param_dict['lead_int']
                                )
    # Write output file
    log.info('Write output file')
    Writer(log).write_class4_out(param_dict, list_keys)
    log.info('End')        

# Set the level of logger (log_level = 2)
# Run the main code
if __name__ == "__main__":
    main()
