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
import logging
import xarray as xr
import numpy as np
import pandas as pd
import netCDF4
from collections import namedtuple, OrderedDict, defaultdict
from copy import deepcopy
from itertools import islice
from joblib import Parallel, delayed, parallel_config
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
                                    compute_rmsd_3d_by_depth_bins,
                                    valid_class4_pairs
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


def _interpolate_forecast(task, log, interpolator=None):
    """Isolate mutable interpolation state in each parallel task."""
    ind_time, dateval, cache_key, obs_data, model_data, varname, params, leadtime, model_mask, data_file = task
    if interpolator is None:
        interpolator = Interpolator(log, dask=params['dask'])
    tick = tm.perf_counter()
    kwargs = dict(datevalue=dateval, leadtime=leadtime, mask_tab=model_mask)
    if data_file is not None:
        kwargs['data_file'] = data_file
    tab_results, is_2D = interpolator.interp_class4(
        obs_data, model_data, [varname], params, **kwargs)
    return (ind_time, cache_key, obs_data, tab_results, is_2D,
            params.get('LEVITUS_clim'), tm.perf_counter() - tick)


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
    parser.add_argument("--no-percentiles", action="store_true",
                        help="Compute classical scores without collecting percentile samples")
    parser.add_argument("--cfg", required=True, help="Local config file for setting inputs and outputs")
    parser.add_argument("--fcst (only forecasts)", action="store_true")
    parser.add_argument("--hdct (only hindcast)", action="store_true")
    parser.add_argument("--all (hdct fcst and pers)", action="store_true")
    parser.add_argument('--workers', type=int, default=1,
                        help='Concurrent forecast interpolation processes (default: 1)')
    parser.add_argument('--cache-size', type=int, default=4,
                        help='Maximum cached observation dates (0 disables caching)')
    args = parser.parse_args()
    if args.cache_size < 0:
        parser.error('--cache-size must be >= 0')
    if args.workers < 1:
        parser.error('--workers must be >= 1')

    # ==================================================================
    #  PART-1 -  Load input parameters
    # ==================================================================
    param_dict, log = Loader().factory('INPUT').load([arg for i, arg in enumerate(sys.argv[1:])
        if not arg.startswith(('--workers=', '--cache-size='))
        and arg not in ('--workers', '--cache-size')
        and not (i > 0 and sys.argv[i] in ('--workers', '--cache-size'))], level)
    log.debug('========================================================')
    log.debug('          Load input options and parameter file test       ')
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
    percentile_depth_bins = [0, 1, 5, 10, 20, 30, 40, 50, 70, 100, 200, 300,
                             400, 500, 600, 700, 800, 900, 1000, 1200, 1400,
                             1600, 1900, 2300, 2600, 2900, 3300, 3600, 4000,
                             4400, 4800, 5200, 5600]
    percentile_depth_names = [f'{lo:g}-{hi:g}m' for lo, hi in
                              zip(percentile_depth_bins[:-1], percentile_depth_bins[1:])]
    percentile_depth_names.append(f'0-{percentile_depth_bins[-1]:g}m')
    depth_names = [
                f"{depth_bins[i]:g}-{depth_bins[i + 1]:g}m"
                    for i in range(len(depth_bins) - 1)
    ]
    depth_names.append(f"0-{depth_bins[-1]:g}m")
    ndepth = len(depth_bins) - 1
    n_depth_outputs = len(depth_names)
    log.debug(f'Build regional area {region_names}')
    log.debug(reg_polygons)

    timings = defaultdict(float)
    started = tm.perf_counter()
    cache_hits = cache_misses = 0
    for selected_var in param_dict['list_variables']:
        log.info(f'{selected_var=}')
        # Read mask value
        maskfile = param_dict['coordinates']
        if selected_var not in list_3D:
            with xr.open_dataset(maskfile) as nc_mask:
                mask = nc_mask[maskname]
                indexers = {
                    dim: 0
                    for dim in ("time_counter", "time", "nav_lev", "depth")
                    if dim in mask.dims
                }
                model_mask = mask.isel(indexers).values.astype(bool)
                lon_mask = nc_mask["nav_lon" if "nav_lon" in nc_mask else "lon"].load()
                lat_mask = nc_mask["nav_lat" if "nav_lat" in nc_mask else "lat"].load()
                if lon_mask.ndim == 1 and lat_mask.ndim == 1:
                    lon2d, lat2d = np.meshgrid(lon_mask.values, lat_mask.values)
                    lon_mask = xr.DataArray(lon2d, dims=("y", "x"))
                    lat_mask = xr.DataArray(lat2d, dims=("y", "x"))
                if conf_type == "ensemble":
                    depth_mask = nc_mask["nav_lev" if "nav_lev" in nc_mask else "depth"].load()

        else:
            if conf_type == "ensemble":
                log.info(f'Read mask ensemble {maskfile}')
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
            dispersion_samples = {} if not args.no_percentiles else None
            anomaly_sums = {} if dispersion_samples is not None else None
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
            obs_cache = OrderedDict()
            region_cache = OrderedDict()
            cache_limit = args.cache_size
            for zarr_file, daterun in zip(input_list_file, list_daterun):
                init_started = tm.perf_counter()
                log.info('Processing %s initialization %s', varname, daterun)
                log.debug('Zarr file: %s', zarr_file)
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
                tick = tm.perf_counter()
                ds = open_zarr(zarr_file)
                timings['Zarr opening'] += tm.perf_counter() - tick
                try:
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
                    log.debug(
                        f"Zarr opened: "
                        f"time={ds.sizes.get('time')}, "
                        f"ens={ds.sizes.get('ens')}, "
                        f"variable={varname}"
                    )
                    if conf_type == "ensemble":
                        log.debug("Compute ensemble mean")
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
                        log.debug('Read model ok')
                    combined_list = []
                    leadtime = param_dict['lead_time'][0]
                    def prepare_forecasts():
                        nonlocal param_dict, cache_hits, cache_misses
                        for ind_time, lead_day in enumerate(param_dict['lead_int']):
                            dateval = list_dates[ind_time]
                            target_date = pd.to_datetime(dateval)
                            log.info('Lead time %s/%s - Date %s', ind_time, N - 1, dateval)
                            tick = tm.perf_counter()
                            cache_key = str(dateval)
                            cached = obs_cache.get(cache_key)
                            if cached is not None:
                                cache_hits += 1
                                obs_cache.move_to_end(cache_key)
                                param_dict.pop('LEVITUS_clim', None)
                                data_file, obs_data, obs_state = deepcopy(cached)
                                param_dict.update(obs_state)
                                timings['Observation cache hits'] += tm.perf_counter() - tick
                            else:
                                cache_misses += 1
                                data_file, ll_miss = global_input.run(param_dict, dateval, save=False)
                                timings['Observation selection'] += tm.perf_counter() - tick
                                if ll_miss:
                                    log.info(f'File is missing for the observation {dateval}')
                                    for iregion in range(nregions):
                                        tab_bias_daily[iregion][ind_time].append(np.nan)
                                        tab_rmsd_daily[iregion][ind_time].append(np.nan)
                                        tab_n_obs_daily[iregion][ind_time].append(0)
                                    continue
                                tick = tm.perf_counter()
                                log.debug(f'{data_file=}')
                                t0 = tm.perf_counter()
                                # Read input obs value
                                log.debug(f"Format of the data {param_dict['data_format']}")
                                log.debug(f"Read pos and value : {param_dict['data_format']}")
                                param_dict.pop('LEVITUS_clim', None)
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
                                if cache_limit:
                                    obs_cache[cache_key] = deepcopy((data_file, obs_data, {k: param_dict[k] for k in ('qc', 'LEVITUS_clim', 'varname_select', 'll_TEMP', 'll_PSAL', 'Design_GODAE_file') if k in param_dict}))
                                if len(obs_cache) > cache_limit:
                                    obs_cache.popitem(last=False)
                                timings['Observation loading'] += tm.perf_counter() - tick
                            # Compute ensemble mean
                            log.info('Loading model for lead %s', ind_time)
                            t0 = tm.perf_counter()
                            if conf_type == "ensemble":
                                dirout = f"{param_dict['diroutput']}"
                                output_file = (
                                        f"{dirout}"
                                        f"{param_dict['cl_conf']}_ensmean_{varname}_"
                                        f"leadtime_{ind_time:03d}_{daterun}.npy"
                                )
                                if Path(output_file).exists():
                                    log.debug(f"Loading existing file: {output_file}")
                                    model_value_day = np.load(output_file)
                                else:
                                    log.debug(f"Computing and saving: {output_file}")
                                    (model_value_day,) = dask.compute(
                                        model_value.isel(time=ind_time)
                                    )
                                    np.save(output_file, model_value_day)
                                    # save dask file
                                    log.debug(f"Save {varname}_leadtime{ind_time}_{daterun}")
                                log.debug(
                                    f"Dask computation of all "
                                    f"{tm.perf_counter() - t0:.2f} s"
                                )
                                log.debug('Apply mask')
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
                                                #"depth": depth_mask.values,
                                                "depth":np.asarray(depth_mask),
                                                "lon": (["y", "x"], lon_mask.values),
                                                "lat": (["y", "x"], lat_mask.values),
                                            },
                                            name="model_data",
                                    )
                                timings['Model loading'] += tm.perf_counter() - t0
                                prepared_model = model_data
                                prepared_file = data_file[0]
                            else:
                                log.debug(f"Case {conf_type} model")
                                (model_value_day,) = dask.compute(
                                    model_value.isel(time=ind_time)
                                )
                                log.debug(
                                    f"Dask computation of all "
                                    f"{tm.perf_counter() - t0:.2f} s"
                                )
                                timings['Model loading'] += tm.perf_counter() - t0
                                prepared_model = model_value_day
                                prepared_file = None
                            log.info('Model loading completed for lead %s in %.2f s', ind_time, tm.perf_counter() - t0)
                            yield (ind_time, dateval, cache_key, obs_data,
                                   prepared_model, varname, param_dict if args.workers == 1 else deepcopy(param_dict),
                                   leadtime, model_mask, prepared_file)
                            del prepared_model, model_value_day
                            if conf_type == 'ensemble':
                                del model_data

                    def interpolated_forecasts():
                        tasks = prepare_forecasts()
                        if args.workers == 1:
                            for task in tasks:
                                log.info('Starting interpolation for lead %s', task[0])
                                result = _interpolate_forecast(task, log, interpolator)
                                del task
                                log.info('Interpolation completed in %.2f s', result[-1])
                                yield result
                                del result
                        else:
                            # Keep only one bounded batch of full model fields in memory.
                            # Workers never write shared regional accumulators.
                            with parallel_config(backend='loky', inner_max_num_threads=1):
                                with Parallel(n_jobs=args.workers, batch_size=1,
                                              pre_dispatch=args.workers) as parallel:
                                    while True:
                                        batch = list(islice(tasks, args.workers))
                                        if not batch:
                                            break
                                        tick = tm.perf_counter()
                                        log.info('Starting parallel interpolation for leads %s', [task[0] for task in batch])
                                        results = parallel(delayed(_interpolate_forecast)(task, log)
                                                           for task in batch)
                                        timings['Parallel interpolation wall'] += tm.perf_counter() - tick
                                        del batch
                                        log.info('Parallel interpolation completed in %.2f s', tm.perf_counter() - tick)
                                        yield from results
                                        del results

                    for ind_time, cache_key, obs_data, tab_results, is_2D, clim, interp_seconds in interpolated_forecasts():
                        timings['Interpolation worker time' if args.workers > 1 else 'Interpolation'] += interp_seconds
                        if clim is not None and np.shape(clim) != np.shape(tab_results['observation']):
                            log.warning('Climatology shape does not match observations; skipping ACC')
                            clim = None
                        log.info('Computing regional statistics for lead %s', ind_time)
                        regional_started = tm.perf_counter()
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
                            tick = tm.perf_counter()
                            cached_region = region_cache.get(cache_key)
                            if (cached_region is None
                                    or not np.array_equal(cached_region[0], obs_lon, equal_nan=True)
                                    or not np.array_equal(cached_region[1], obs_lat, equal_nan=True)):
                                cached_region = (obs_lon.copy(), obs_lat.copy(), {})
                                if cache_limit:
                                    region_cache[cache_key] = cached_region
                                    if len(region_cache) > cache_limit:
                                        region_cache.popitem(last=False)
                            if cache_limit:
                                region_cache.move_to_end(cache_key)
                            masks = cached_region[2]
                            if iregion not in masks:
                                masks[iregion] = contains_xy(polygon, obs_lon, obs_lat)
                            region_mask = masks[iregion]
                            timings['Regional selection'] += tm.perf_counter() - tick
                            n_region = np.count_nonzero(region_mask)
                            log.debug(
                                f"********************************"
                                f"Region {iregion} {region_name}: "
                                f"{n_region} observations"
                            )
                            # ------------------------------------------------------
                            # No observations in this region
                            # ------------------------------------------------------

                            if n_region == 0:
                                if is_2D:
                                    if is_3D:
                                        for idepth in range(n_depth_outputs):
                                            tab_bias_daily[iregion][idepth][ind_time].append(np.nan)
                                            tab_rmsd_daily[iregion][idepth][ind_time].append(np.nan)
                                            tab_n_obs_daily[iregion][idepth][ind_time].append(0)
                                    else:
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
                            log.debug("Observation shape: %s", np.shape(tab_results["observation"]))
                            regional_observation = \
                                    tab_results["observation"][region_mask]
                            regional_depth = \
                                    tab_results["depth"][region_mask]
                            regional_qc = obs_data.qc[region_mask]
                            #regional_qc = tab_results["qc"][region_mask]
                            tick = tm.perf_counter()
                            # Collect matched samples by region, depth and leadtime.
                            # The final quantiles must use the full period distribution.
                            if dispersion_samples is not None and is_2D:
                                pairs = valid_class4_pairs(
                                    np.squeeze(regional_model),
                                    np.squeeze(regional_observation),
                                )
                                if pairs[0].size:
                                    dispersion_samples.setdefault(
                                        (iregion, ind_time), []
                                    ).append(np.column_stack(pairs))
                            elif dispersion_samples is not None:
                                depths = np.ma.asarray(np.squeeze(regional_depth))
                                model = np.ma.asarray(np.squeeze(regional_model))
                                obs = np.ma.asarray(np.squeeze(regional_observation))
                                qc = np.ma.asarray(np.squeeze(regional_qc))
                                regional_clim = None if clim is None else np.ma.asarray(np.squeeze(clim[region_mask]))
                                for idepth in range(len(percentile_depth_bins) - 1):
                                    in_bin = ((depths >= percentile_depth_bins[idepth])
                                              & (depths < percentile_depth_bins[idepth + 1]))
                                    qc_bin = np.ma.masked_where(~in_bin, qc)
                                    model_bin = np.ma.masked_where(~in_bin, model)
                                    obs_bin = np.ma.masked_where(~in_bin, obs)
                                    pair = valid_class4_pairs(
                                        model_bin, obs_bin, qc=qc_bin,
                                    )
                                    if regional_clim is not None:
                                        clim_bin = np.ma.masked_where(~in_bin, regional_clim)
                                        c = np.ma.filled(clim_bin.astype(float), np.nan)
                                        valid = np.isfinite(c) & (np.abs(c) <= 1.e30)
                                        m = np.ma.masked_where(~valid, model_bin)
                                        o = np.ma.masked_where(~valid, obs_bin)
                                        # Subtract climatology only after applying the original pair mask.
                                        mv = np.ma.filled(m.astype(float), np.nan)
                                        ov = np.ma.filled(o.astype(float), np.nan)
                                        good = (valid & np.isfinite(mv) & np.isfinite(ov)
                                                & (np.abs(mv) <= 1.e30) & (np.abs(ov) <= 1.e30)
                                                & (np.ma.filled(qc_bin, -9999) == 0))
                                        pa, ra = mv[good] - c[good], ov[good] - c[good]
                                        sums = np.array([len(pa), np.dot(pa, ra),
                                                         np.dot(pa, pa), np.dot(ra, ra)], dtype=float)
                                        for k in (idepth, len(percentile_depth_bins) - 1):
                                            key = (iregion, k, ind_time)
                                            anomaly_sums.setdefault(key, np.zeros(4))[:] += sums
                                    if pair[0].size:
                                        dispersion_samples.setdefault(
                                            (iregion, idepth, ind_time), []
                                        ).append(np.column_stack(pair))
                                        dispersion_samples.setdefault(
                                            (iregion, len(percentile_depth_bins) - 1, ind_time), []
                                        ).append(np.column_stack(pair))
                            timings['Extended statistics'] += tm.perf_counter() - tick
                            tick = tm.perf_counter()
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
                                log.debug(f"Results RMSD : {iregion} {region_name} {ind_time} ,  {daily_rmsd}")
                                log.debug(f"Results BIAS : {iregion} {region_name} {ind_time} ,  {daily_bias}")
                                log.debug(f"Cumul RMSD {tab_cumul_sq_diff[iregion][ind_time]}")
                                log.debug(f"Cumul bias daily {daily_cumul_bias} cumul rmsd {daily_cumul_sq_diff}")
                                if log.isEnabledFor(logging.DEBUG) and len(obs_data.lon):
                                    log.debug("Results %%: bad value %s", nb_bad / len(obs_data.lon) * 100)
                            else:
                                log.debug(f"3D stats")
                                log.debug("MODEL shape: %s", np.shape(regional_model))
                                log.debug("OBS shape: %s", np.shape(regional_observation))
                                log.debug("DEPTH shape: %s", np.shape(regional_depth))
                                log.debug("QC shape: %s", np.shape(regional_qc))

                                if log.isEnabledFor(logging.DEBUG):
                                    log.debug("MODEL range: %s %s",
                                                     np.nanmin(regional_model), np.nanmax(regional_model))
                                    log.debug("OBS range: %s %s",
                                                     np.nanmin(regional_observation), np.nanmax(regional_observation))

                                    log.debug("QC unique values: %s", np.unique(regional_qc))
                                log.debug("DEPTH bins: %s", depth_bins)
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
                                    log=log,
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
                                    log.debug(
                                        f"RMSD daily depth "
                                        f"{depth_names[idepth]} "
                                        f"{daily_rmsd=} "
                                        f"{region_name=}"
                                    )

                                    log.debug(
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
                            timings['Classical statistics'] += tm.perf_counter() - tick
                        log.info('Regional statistics completed for lead %s in %.2f s', ind_time, tm.perf_counter() - regional_started)
                finally:
                    ds.close()
                    log.info('Initialization %s elapsed %.2f s; main process peak RSS %.1f MiB',
                             daterun, tm.perf_counter() - init_started,
                             resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024)
            outputname = (f"{param_dict['diroutput']}results_regional_scores_class4_optim_{param_dict['data_type']}"
                          f"_{param_dict['cl_conf']}_{varname}_forecast_{date1}_{date2}.nc"
                         )
            log.info(f"Save results {varname} {outputname}")

            lead_times = param_dict['lead_int']
            tick = tm.perf_counter()
            save_metrics_to_netcdf_regional(tab_cumul_sq_diff,
                                   tab_cumul_bias,
                                   tab_n_obs,
                                   tab_rmsd_daily,
                                   tab_bias_daily,
                                   tab_n_obs_daily,
                                   region_names,
                                   lead_times,
                                   outputname,
                                   depth_names=depth_names,
                                   dispersion_samples=dispersion_samples,
                                   percentile_depth_names=percentile_depth_names if is_3D else None,
                                   anomaly_sums=anomaly_sums)
            timings['NetCDF writing'] += tm.perf_counter() - tick
    elapsed = tm.perf_counter() - started
    log.info('Performance report: %.2f s total; cache hits=%d misses=%d', elapsed, cache_hits, cache_misses)
    for name, seconds in timings.items():
        log.info('%s: %.2f s (%.1f%%)', name, seconds, 100 * seconds / max(elapsed, 1e-9))

# Set the level of logger (log_level = 2)
# Run the main code
if __name__ == "__main__":
    main()
