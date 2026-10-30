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
from tep_class4.core.utils import create_dict, save_metrics_to_netcdf_regional
from tep_class4.core.utils import (generate_date_list,
                                  generate_nbdateslist,
                                  build_zarr_list,
                                  build_zarr_list_ai,
                                  open_zarr,
                                  get_surface_ensemble_mean,
                                  build_region_polygons)
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
    ObsData = namedtuple("ObsData", ["lon", "lat", "obs_value", "nb_obs", "depth", "dims", "FillValue", "qc"])
    interpolator = Interpolator(log, dask=param_dict['dask'])
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

    for selected_var in param_dict['list_variables']:
        log.info(f'{selected_var=}')
        # Read mask value
        maskfile = param_dict['coordinates']
        if selected_var not in list_3D:
            if conf_type == "ensemble":
                with xr.open_dataset(maskfile) as nc_mask:
                    model_mask = nc_mask[maskname].isel(
                        time_counter=0,
                        nav_lev=0,
                        ).values.astype(bool)
                    lon_mask = nc_mask["nav_lon"]
                    lat_mask = nc_mask["nav_lat"]
                    depth_mask = nc_mask["nav_lev"]
            else:
                with xr.open_dataset(maskfile) as nc_mask:
                    model_mask = nc_mask[maskname].isel(
                    #    time_counter=0,
                        nav_lev=0,
                        ).values.astype(bool)
                    lon_mask = nc_mask["nav_lon"]
                    lat_mask = nc_mask["nav_lat"]

        else:
            if conf_type == "ensemble":
                log.info('Read mask ensemble')
                with xr.open_dataset(maskfile) as nc_mask:
                    model_mask = nc_mask[maskname].isel(
                        time_counter=0,
                        ).values.astype(bool)
                    model_mask = np.squeeze(
                            nc_mask[maskname].values.astype(bool)
                    )
                    lon_mask = nc_mask["nav_lon"]
                    lat_mask = nc_mask["nav_lat"]
                    depth_mask = np.array(nc_mask["nav_lev"])
                    log.info(f'{np.shape(model_mask)}')
            else:
                with xr.open_dataset(maskfile) as nc_mask:
                    #model_mask = nc_mask[maskname].isel(
                    #    time_counter=0,
                    #    ).values.astype(bool)
                    model_mask = np.squeeze(
                        nc_mask[maskname].values.astype(bool)
                    )
                    #lon_mask = nc_mask["nav_lon"]
                    #lat_mask = nc_mask["nav_lat"]
                    lon_mask = nc_mask["longitude"]
                    lat_mask = nc_mask["latitude"]
        if selected_var in list_surface_SST: filter_levels = True
        param_dict['prefix_data'] = param_dict['prefix_data_all'][selected_var]
        param_dict['data_format'] = param_dict['data_format_all'][selected_var]
        param_dict['data_type'] = selected_var
        param_dict['dirdata'] = param_dict['dirdata_all'][selected_var]
        param_dict['varname'] = param_dict['varname_all'][selected_var]
        param_dict['cl_src'] = param_dict['typedata_all'][selected_var]
        gridtype_list =  param_dict['gridtype'][selected_var]
        for ind, varname in enumerate(param_dict['varname']):
            gridtype = gridtype_list[ind]
            #gridtype = param_dict['gridtemp']
            # READ Model file
            if param_dict['is_zarr']:
                log.debug("Read zarr file")
            date1 = param_dict['date1']
            date2 = param_dict['date2']
            #variable = param_dict['varname']
            #if isinstance(variable, str):
            #    variable = [variable]
            log.info(
                    f"Work on selected variable {selected_var} \n"
                    f"TYPE {param_dict['data_type']} \n"
                    f"SRC : {param_dict['cl_src']} \n"
                    f"gridtype : {gridtype}"
            )
            if param_dict['cl_typemod'].lower() == 'pgn':
                if conf_type == "ensemble":
                    bucket_name = param_dict['bucket_name']
                    endpoint_url = param_dict['url_cloud']
                    input_list_file, list_daterun = build_zarr_list(date1,
                                                      date2,
                                                      bucket_name = bucket_name,
                                                      endpoint_url = endpoint_url,
                                                      gridtype = gridtype
                                                      )
            elif param_dict['cl_typemod'].lower() == 'pgs_ai':
                bucket_name = param_dict['bucket_name']
                endpoint_url = param_dict['url_cloud']
                input_list_file, list_daterun = build_zarr_list_ai(date1,
                                                  date2,
                                                  bucket_name = bucket_name,
                                                  endpoint_url = endpoint_url,
                                                  gridtype = gridtype
                                                  )

            log.info(f'File {input_list_file}')
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
            for zarr_file, daterun in zip(input_list_file, list_daterun):
                log.info('------- Zarr daterun--------------')
                log.info(f"{zarr_file} {daterun}")
                log.info('----------------------------------')
                # Generate forecast date for observations
                list_dates = generate_nbdateslist(daterun, nb_forecasts)
                log.debug(f'List of forecast dates {list_dates}')
                # Selection of the input data
                selector = Selector(
                                    param_dict['data_format'],
                                    param_dict['data_type'],
                                    log
                                   )
                global_input = selector.factory("GLOBAL_INPUT_DATA")
                # Open zarr Model file
                ds = open_zarr(zarr_file)
                if gridtype == '3DU-uo':
                    depth_name = "depthu"
                elif gridtype == '3DV-vo':
                    depth_name = "depthv"
                elif gridtype == '3DT-thetao':
                    depth_name = "deptht"
                elif gridtype == '3DT-so':
                    depth_name = "deptht"
                #else:
                #    log.error("Variable not known {gridtype}")
                #    sys.exit(1)
                log.info(
                    f"Zarr opened: "
                    f"time={ds.sizes.get('time')}, "
                    f"ens={ds.sizes.get('ens')}, "
                    f"variable={varname}"
                )
                if conf_type == "ensemble":
                    log.info(f"Compute ensemble mean")
                    # Compute ensemble mean
                    model_value = get_surface_ensemble_mean(
                        ds,
                        variable=varname,
                    )
                    log.debug(f'Compute ensemble ok')
                else:
                    model_value = (
                        ds[varname]
                        .astype(np.float32)
                    )
                    log.info(f'Read model ok')
                combined_list = []
                leadtime = param_dict['lead_time'][0]
                for ind_time, lead_day in enumerate(param_dict['lead_int']):
                    dateval = list_dates[ind_time]
                    target_date = pd.to_datetime(dateval)
                    log.info(
                             f"Selection of input data {param_dict['data_format']} "
                             #f"{param_dict['data_type']} \n"
                             f"For {dateval=} \n"
                             f"Leadtime {ind_time} / {N}"
                            )
                    log.info('=================================================')
                    data_file, ll_miss = global_input.run(param_dict, dateval, save=False)
                    if ll_miss:
                        log.info(f'File is missing for the observation {dateval}')
                        for iregion in range(nregions):
                            tab_bias_daily[iregion][ind_time].append(np.nan)
                            tab_rmsd_daily[iregion][ind_time].append(np.nan)
                            tab_n_obs_daily[iregion][ind_time].append(0)
                        continue
                    log.info(f'{data_file=}')
                    t0 = tm.perf_counter()
                    # Read input obs value
                    log.debug(f"Format of the data {param_dict['data_format']}")
                    log.debug(f"Read pos and value : {param_dict['data_format']}")
                    lon_obs, lat_obs, obs_value, nb_obs, depth, \
                        tab_qc, tab_dims, param_dict, _FillValue = \
                        inputdata_loader(log).factory(param_dict['data_format']).\
                        read_pos_and_value(data_file[0],
                            param_dict,
                            filter_levels=filter_levels,
                            input_var = [varname],
                            selected_var = selected_var,
                        )
                    log.debug(f"Dimensions {np.shape(obs_value)}")
                    log.debug(f"Dimension depth {np.shape(depth)}")
                    log.debug(f"Dimension depth {np.shape(tab_qc)}")
                    nbs_obs, nbdepth = np.shape(depth)
                    log.debug(f"{filter_levels=}")
                    obs_data = ObsData(lon_obs,
                                       lat_obs,
                                       obs_value,
                                       nb_obs, depth,
                                       tab_dims,
                                       _FillValue,
                                       tab_qc
                    )
                    # Compute ensemble mean
                    log.info('Get model value')
                    t0 = tm.perf_counter()
                    if conf_type == "ensemble":
                        dirout = f"{param_dict['diroutput']}"
                        output_file = (
                                f"{dirout}"
                                f"{param_dict['cl_conf']}_ensmean_{varname}_"
                                f"leadtime_{ind_time:03d}_{daterun}.npy"
                        )
                        if Path(output_file).exists():
                            log.info(f"Loading existing file: {output_file}")
                            model_value_day = np.load(output_file)
                        else:
                            log.info(f"Computing and saving: {output_file}")
                            (model_value_day,) = dask.compute(
                                model_value.isel(time=ind_time)
                            )
                            np.save(output_file, model_value_day)
                            # save dask file
                            log.info(f"Save {varname}_leadtime{ind_time}_{daterun}")
                        log.info(
                            f"Dask computation of all "
                            f"{tm.perf_counter() - t0:.2f} s"
                        )
                        log.info('Apply mask')
                        # Apply mask
                        model_value_day = np.squeeze(np.where(
                            model_mask,
                            model_value_day,
                            np.nan,
                        ))
                        if model_value_day.ndim == 2:
                            model_data = xr.DataArray(
                                model_value_day,
                                dims=["y", "x"],
                                coords={
                                    "lon": (["y", "x"], lon_mask.values),
                                    "lat": (["y", "x"], lat_mask.values),
                                },
                                name="model_data",
                            )
                        elif model_value_day.ndim == 3:
                            # 3D: (depth, y, x)
                            model_data = xr.DataArray(
                                    model_value_day,
                                    dims=["depth", "y", "x"],
                                    coords={
                                        "depth": depth_mask.values,
                                        "lon": (["y", "x"], lon_mask.values),
                                        "lat": (["y", "x"], lat_mask.values),
                                    },
                                    name="model_data",
                            )
                        tab_results, is_2D = \
                            interpolator.interp_class4(obs_data,
                                                        model_data,
                                                        [varname],
                                                        param_dict,
                                                        datevalue=dateval,
                                                        leadtime=leadtime,
                                                        mask_tab=model_mask,
                                                        )
                    else:
                        log.info(f"Case {conf_type} model")
                        (model_value_day,) = dask.compute(
                            model_value.isel(time=ind_time)
                        )
                        log.info(
                            f"Dask computation of all "
                            f"{tm.perf_counter() - t0:.2f} s"
                        )
                        tab_results, is_2D = \
                            interpolator.interp_class4(obs_data,
                                                        model_value_day,
                                                        [varname],
                                                        param_dict,
                                                        datevalue=dateval,
                                                        leadtime=leadtime,
                                                        mask_tab=model_mask)

                    # Loop over regions
                    obs_lon = np.asarray(tab_results["lon"])
                    obs_lat = np.asarray(tab_results["lat"])
                    # ==========================================================
                    # Loop over regions
                    # ==========================================================
                    for iregion, region_name in enumerate(region_names):
                        polygon = reg_polygons[region_name]
                        # ------------------------------------------------------
                        # Select observations belonging to this region
                        # ------------------------------------------------------
                        region_mask = contains_xy(
                            polygon,
                            obs_lon,
                            obs_lat,
                        )
                        n_region = np.count_nonzero(region_mask)
                        log.info(
                            f"********************************"
                            f"Region {iregion} {region_name}: "
                            f"{n_region} observations"
                        )
                        # ------------------------------------------------------
                        # No observations in this region
                        # ------------------------------------------------------

                        if n_region == 0:
                            if is_2D:
                                tab_bias_daily[iregion][ind_time].append(np.nan)
                                tab_rmsd_daily[iregion][ind_time].append(np.nan)
                                tab_n_obs_daily[iregion][ind_time].append(0)
                                continue
                            else:
                                for idepth in range(n_depth_outputs):
                                    tab_bias_daily[iregion][idepth][ind_time].append(np.nan)
                                    tab_rmsd_daily[iregion][idepth][ind_time].append(np.nan)
                                    tab_n_obs_daily[iregion][idepth][ind_time].append(0)
                                continue
                        regional_model = np.asarray(
                            tab_results["model"]
                        )[region_mask]
                        #regional_observation = np.asarray(
                        #    tab_results["observation"]
                        #)[region_mask]
                        print(np.shape(tab_results["observation"]))
                        regional_observation = \
                                tab_results["observation"][region_mask]
                        regional_depth = \
                                tab_results["depth"][region_mask]
                        regional_qc = obs_data.qc[region_mask]
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
                            log.info(f"Results RMSD : {iregion} {region_name} {ind_time} ,  {daily_rmsd}")
                            log.info(f"Results BIAS : {iregion} {region_name} {ind_time} ,  {daily_bias}")
                            log.debug(f"Cumul RMSD {tab_cumul_sq_diff[iregion][ind_time]}")
                            log.debug(f"Cumul bias daily {daily_cumul_bias} cumul rmsd {daily_cumul_sq_diff}")
                            log.debug(f"Results %: bad value {(nb_bad/len(obs_value))*100}")
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
    
            outputname = (f"{param_dict['diroutput']}results_regional_scores_class4_{param_dict['data_type']}"
                          f"_{param_dict['cl_conf']}_{varname}_forecast_{date1}_{date2}.nc"
                         )
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
