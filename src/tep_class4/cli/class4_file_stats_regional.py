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
import netCDF4
from collections import namedtuple
import time as tm
import dask
from pathlib import Path
from shapely import contains_xy
from glob import glob
from joblib import Parallel, delayed

# Import local modules
from tep_class4.core.Selector import Selector
from tep_class4.core.Loader import Loader
from tep_class4.core.arithm import (init_array_1D,
                                    init_array_2D_null,
                                    compute_rmsd,
                                    nanrmse,
                                    init_array_3D_null,
                                    compute_rmsd_3d_by_depth_bins
                                    )
from tep_class4.core.Interpolator import Interpolator
from tep_class4.core.Writer import Writer
from tep_class4.core.reader import read_qc_CLASS4
from tep_class4.core.utils import (create_dict,
                                  save_metrics_to_netcdf_regional,
                                  compute_region_mask
                                  )
from tep_class4.core.utils import (generate_date_list,
                                  generate_nbdateslist,
                                  build_zarr_list,
                                  build_zarr_list_ai,
                                  open_zarr,
                                  get_surface_ensemble_mean,
                                  build_region_polygons,
                                  create_listdate,
                                  filter_data
                                  )
from tep_class4.core.inputdata_loader import inputdata_loader
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY,
                                           resource.RLIM_INFINITY))


def main(level=2):
    """
    Main TEP CLASS4 function
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True)
    #parser.add_argument("--daterun", required=True)
    parser.add_argument("--src", required=True)
    parser.add_argument("--date1", required=True)
    parser.add_argument("--date2", required=True)
    parser.add_argument("--data", required=True)
    parser.add_argument("--typemod", required=True)
    parser.add_argument("--loglevel", type=int, default=2)
    parser.add_argument("--zarr", action="store_true")
    parser.add_argument("--cfg", required=True, help="Local config file for setting inputs and outputs")
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
    # Load local config
    log.debug(f"Load local conf {param_dict['confname_local']}")
    param_dict = Loader.factory('NML').load(param_dict['confname_local'], level, param_dict, log)
    # Load db configuration model file
    conf_path = dirname(__file__)
    list_surface_SST = ['profile_TS_DB']
    filename = conf_path + '/cfg/' + param_dict['confname']
    param_dict = Loader.factory('NML').load(filename, level, param_dict, log)
    nb_forecasts = len(param_dict['lead_int'])
    nb_leadtimes = len(param_dict['lead_time'])
    conf_type = param_dict['conf_type']
    maskname = param_dict['maskname']
    log.info(f"{nb_forecasts=} {nb_leadtimes=}")
    # Create polygons
    reg_polygons = build_region_polygons(
            param_dict['area_file']
    )
    region_names = list(reg_polygons.keys())
    nregions = len(region_names)
    filter_levels = True
    SST_treshold = 10
    list_temp = ['thetao', 'votemper']
    list_psal = ['so', 'vosaline']
    list_3D = ['profile_PR_PF']
    #, 'DRIFTER_filtr']
    depth_bins = param_dict['DEPTHS']
    depth_names = [
                f"{depth_bins[i]:g}-{depth_bins[i + 1]:g}m"
                    for i in range(len(depth_bins) - 1)
    ]
    depth_names.append(f"0-{depth_bins[-1]:g}m")
    ndepth = len(depth_bins) - 1
    n_depth_outputs = len(depth_names)
    log.debug(f'Build regional area {region_names}')
    log.debug(reg_polygons)
    data_class4 =  param_dict['data_class4']
    date1 = param_dict['date1']
    date2 = param_dict['date2']
    list_date = create_listdate(date1, date2)
    config =  param_dict['cl_conf']
    is_2D = True
    for selected_var in param_dict['list_variables']:
        log.info(f'{selected_var=}')
        param_dict['data_type'] = selected_var
        if selected_var in list_3D:
            is_2D = False
        for ind, varname in enumerate(param_dict['varname_all'][selected_var]):
            outputname = (f"{param_dict['diroutput']}results_regional_scores_class4-files_{param_dict['data_type']}"
                          f"_{param_dict['cl_conf']}_{varname}_forecast_{date1}_{date2}.nc"
                         )
            N = len(param_dict['lead_int'])
            is_3D = selected_var in list_3D
            if is_3D:
                (tab_cumul_sq_diff,
                    tab_cumul_bias, tab_n_obs) = (
                            init_array_3D_null(nregions, n_depth_outputs, N) 
                            for _ in range(3)
                )
                # Daily values:
                # [region][depth][leadtime]
                tab_rmsd_daily = [
                    [
                        [[] for _ in range(N)]
                        for _ in range(n_depth_outputs)
                    ]
                    for _ in range(nregions)
                ]

                tab_bias_daily = [
                    [
                        [[] for _ in range(N)]
                        for _ in range(n_depth_outputs)
                    ]
                    for _ in range(nregions)
                ]

                tab_n_obs_daily = [
                    [
                        [[] for _ in range(N)]
                        for _ in range(n_depth_outputs)
                    ]
                    for _ in range(nregions)
                ]
            else:
                (tab_cumul_sq_diff,
                    tab_cumul_bias, tab_n_obs) = (
                            init_array_2D_null(nregions, N)
                            for _ in range(3)
                )
                # Keep daily values for each leadtime
                tab_rmsd_daily = [
                    [[] for _ in range(N)]
                    for _ in range(nregions)
                ]
                tab_bias_daily = [
                    [[] for _ in range(N)]
                    for _ in range(nregions)
                ]
                tab_n_obs_daily = [
                    [[] for _ in range(N)]
                    for _ in range(nregions)
                ]
            #for zarr_file, daterun in zip(input_list_file, list_daterun):

            for i, dateval in enumerate(list_date):
                # Get obs file
                try:
                    tab_results = {}
                    filename = glob(f'{data_class4}class4_{dateval}_{config}*_{selected_var}.nc')
                    print(f'{filename=}')
                    ds = xr.open_dataset(filename[0])
                except:
                    print(f'Missing file {data_class4}class4_{dateval}*{config}*_{selected_var}.nc')
                    continue

                log.info('------- File--------------')
                log.info(f"{filename}")
                log.info('----------------------------------')
                tab_results = filter_data(ds, selected_var)

                # Compute regional mask by regions
                obs_lon = np.asarray(tab_results["longitude"])
                obs_lat = np.asarray(tab_results["latitude"])

                # Regional masks do NOT depend on leadtime
                results_regions = Parallel(
                    n_jobs=-1,
                    backend="threading",
                )(
                    delayed(compute_region_mask)(
                        region_name,
                        reg_polygons[region_name],
                        obs_lon,
                        obs_lat,
                    )
                    for region_name in region_names
                )
                regional_data = []
                for (
                    region_name,
                    region_mask,
                    n_region,
                ) in results_regions:
                    if n_region < 10:
                        regional_data.append(None)
                        continue
                    regional_data.append(
                        {
                            "mask": region_mask,
                            "n_region": n_region,
                            "observation": np.asarray(
                                tab_results["observation"][
                                    region_mask
                                ]
                            ),
                            "depth": np.asarray(
                                tab_results["depth"][
                                    region_mask
                                ]
                            ),
                            "qc": np.asarray(
                                tab_results["qc"][
                                    region_mask
                                ]
                            ),
                        }
                    )
                #for iregion, region_name in enumerate(region_names):
                #    region_mask = contains_xy(
                #        reg_polygons[region_name],
                #        obs_lon,
                #        obs_lat,
                #    )
                #    n_region = np.count_nonzero(region_mask)
                #    log.debug(
                #        f"Region {iregion} {region_name}: "
                #        f"{n_region} observations"
                #    )
                #    if n_region < 10:
                #        regional_data.append(None)
                #        continue
                #    regional_data.append(
                #        {
                #            "mask": region_mask,
                #            "n_region": n_region,
                #            "observation": np.asarray(
                #                tab_results["observation"][region_mask]
                #            ),
                #            "depth": np.asarray(
                #                tab_results["depth"][region_mask]
                #            ),
                #            "qc": np.asarray(
                #                tab_results["qc"][region_mask]
                #            ),
                #        }
                #    )
                for ind_time, lead_day in enumerate(param_dict['lead_int']):
                    log.info(f'Leadtime {ind_time}')
                    regional_model_all = np.asarray(
                            tab_results["model_equi"][:, ind_time]
                    )
                    #tab_results["model"] =  tab_results["model_equi"][:, ind_time]
                    # ==========================================================
                    # Loop over regions
                    # ==========================================================
                    for iregion, region_name in enumerate(region_names):

                        region_data = regional_data[iregion]

                        #polygon = reg_polygons[region_name]
                        ## ------------------------------------------------------
                        ## Select observations belonging to this region
                        ## ------------------------------------------------------
                        #region_mask = contains_xy(
                        #    polygon,
                        #    obs_lon,
                        #    obs_lat,
                        #)
                        if region_data is None:
                            if is_2D:
                                tab_bias_daily[
                                    iregion
                                ][ind_time].append(np.nan)
                                tab_rmsd_daily[
                                    iregion
                                ][ind_time].append(np.nan)
                                tab_n_obs_daily[
                                    iregion
                                ][ind_time].append(0)
                            else:
                                for idepth in range(
                                    n_depth_outputs
                                ):
                                    tab_bias_daily[
                                        iregion
                                    ][idepth][ind_time].append(
                                        np.nan
                                    )
                                    tab_rmsd_daily[
                                        iregion
                                    ][idepth][ind_time].append(
                                        np.nan
                                    )
                                    tab_n_obs_daily[
                                        iregion
                                    ][idepth][ind_time].append(
                                        0
                                    )
                            continue
                        # -----------------------------------------------
                        # Valid region: select model
                        # -----------------------------------------------

                        regional_model = (
                            regional_model_all[
                                region_data["mask"]
                            ]
                        )
                        regional_observation = (
                            region_data["observation"]
                        )
                        regional_qc = (
                            region_data["qc"]
                        )
                        n_region = (
                            region_data["n_region"]
                        )
                        log.debug(
                            f"********************************"
                            f"Region {iregion} {region_name}: "
                            f"{n_region} observations"
                        )
                        ## ------------------------------------------------------
                        ## No observations in this region
                        ## ------------------------------------------------------

                        #if n_region < 10:
                        #    if is_2D:
                        #        tab_bias_daily[iregion][ind_time].append(np.nan)
                        #        tab_rmsd_daily[iregion][ind_time].append(np.nan)
                        #        tab_n_obs_daily[iregion][ind_time].append(0)
                        #        continue
                        #    else:
                        #        for idepth in range(n_depth_outputs):
                        #            tab_bias_daily[iregion][idepth][ind_time].append(np.nan)
                        #            tab_rmsd_daily[iregion][idepth][ind_time].append(np.nan)
                        #            tab_n_obs_daily[iregion][idepth][ind_time].append(0)
                        #        continue
                        #regional_model = np.asarray(
                        #    tab_results["model"]
                        #)[region_mask]
                        ##regional_observation = np.asarray(
                        ##    tab_results["observation"]
                        ##)[region_mask]
                        #regional_observation = \
                        #        tab_results["observation"][region_mask]
                        #regional_depth = \
                        #        tab_results["depth"][region_mask]
                        #regional_qc = tab_results["qc"][region_mask]
                        # Compute results
                        if is_2D:
                            depth_names = None
                            log.debug(f"2D case")
                            (
                                daily_bias,
                                daily_cumul_bias,
                                daily_rmsd,
                                daily_cumul_sq_diff,
                                daily_n_obs,
                                nb_bad,
                            ) = compute_rmsd(
                                np.squeeze(regional_model),
                                np.squeeze(regional_observation),
                                n_region,
                                threshold=SST_treshold,
                            )
                            # --------------------------------
                            # Accumulate global statistics
                            # --------------------------------

                            tab_cumul_bias[iregion, ind_time] += daily_cumul_bias
                            tab_cumul_sq_diff[iregion, ind_time] += daily_cumul_sq_diff
                            tab_n_obs[iregion, ind_time] += daily_n_obs

                            # --------------------------------
                            # Keep daily statistics
                            # --------------------------------
                            tab_bias_daily[iregion][ind_time].append(daily_bias)
                            tab_rmsd_daily[iregion][ind_time].append(daily_rmsd)
                            tab_n_obs_daily[iregion][ind_time].append(daily_n_obs)

                            log.debug(f'{tab_rmsd_daily[iregion][ind_time]} {tab_bias_daily[iregion][ind_time]}')
                            log.debug(f'Leadtime {ind_time} {dateval}')
                            log.debug(f"Results RMSD : {iregion} {region_name} {ind_time} ,  {daily_rmsd}")
                            log.debug(f"Results BIAS : {iregion} {region_name} {ind_time} ,  {daily_bias}")
                            log.debug(f"Cumul RMSD {tab_cumul_sq_diff[iregion][ind_time]}")
                            log.debug(f"Cumul bias daily {daily_cumul_bias} cumul rmsd {daily_cumul_sq_diff}")
                            #log.debug(f"Results %: bad value {(nb_bad/len(np.squeeze(regional_observation)))*100}")
                        else:
                            log.info(f"3D stats")
                            (
                                daily_bias_bins,
                                daily_cumul_bias_bins,
                                daily_rmsd_bins,
                                daily_cumul_sq_diff_bins,
                                daily_n_obs_bins,
                            ) = compute_rmsd_3d_by_depth_bins(
                                np.squeeze(regional_model),
                                np.squeeze(regional_observation),
                                np.squeeze(regional_depth),
                                np.squeeze(regional_qc),
                                depth_bins,
                                good_qc=0,
                            )
                            ndepth = len(depth_bins) - 1
                            n_depth_outputs = ndepth + 1

                            for idepth in range(n_depth_outputs):

                                daily_bias = daily_bias_bins[idepth]
                                daily_cumul_bias = daily_cumul_bias_bins[idepth]
                                daily_rmsd = daily_rmsd_bins[idepth]
                                daily_cumul_sq_diff = (
                                    daily_cumul_sq_diff_bins[idepth]
                                )
                                daily_n_obs = daily_n_obs_bins[idepth]
                                log.info(
                                    f"RMSD daily depth "
                                    f"{depth_names[idepth]} "
                                    f"{daily_rmsd=} "
                                    f"{region_name=}"
                                )

                                log.info(
                                    f"BIAS daily depth "
                                    f"{depth_names[idepth]} "
                                    f"{daily_bias=} "
                                    f"{region_name=}"
                                )
                                tab_cumul_bias[iregion, idepth, ind_time,] += daily_cumul_bias
                                tab_cumul_sq_diff[iregion, idepth, ind_time,] += daily_cumul_sq_diff
                                tab_n_obs[iregion, idepth, ind_time,] += daily_n_obs
                                tab_bias_daily[iregion][idepth][ind_time].append(daily_bias)
                                tab_rmsd_daily[iregion][idepth][ind_time].append(daily_rmsd)
                                tab_n_obs_daily[iregion][idepth][ind_time].append(daily_n_obs)
    
            #outputname = (f"{param_dict['diroutput']}results_regional_scores_class4-files_{param_dict['data_type']}"
            #             f"_{param_dict['cl_conf']}_{varname}_forecast_{date1}_{date2}.nc"
            #             )
            log.info(f"Save results {varname} {outputname}")

            lead_times = param_dict['lead_int']
            save_metrics_to_netcdf_regional(tab_cumul_sq_diff,
                                   tab_cumul_bias,
                                   tab_n_obs,
                                   tab_bias_daily,
                                   tab_rmsd_daily,
                                   tab_n_obs_daily,
                                   region_names,
                                   lead_times,
                                   outputname,
                                   depth_names=depth_names)

# Set the level of logger (log_level = 2)
# Run the main code
if __name__ == "__main__":
    main()
