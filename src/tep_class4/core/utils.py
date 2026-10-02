# Module with utilities
import numpy as np
import sys
import re
import pandas as pd
import datetime as dt
import os
import getopt
import shlex
import subprocess
from datetime import datetime
import traceback
from .loader_post import load_db
from dateutil.relativedelta import relativedelta
from datetime import timedelta
from joblib import cpu_count
import yaml
import s3fs
import xarray as xr
import json
from datetime import datetime
from shapely.geometry import shape
from shapely import contains_xy, Polygon
from antimeridian import fix_shape
import time
import copy

__version__ = 0.2
__date__ = "Octobre 2021"
__author__ = "C.REGNIER"

def build_region_polygons(geojson_file):
    """Create polygons for GeoJSON

    Handles regions crossing the antimeridian and regions enclosing
    the North or South Pole.

    Parameters
    ----------
    geojson_file : str
        Path to the GeoJSON file containing the region polygons.
    Returns
    -------
    dict
        Dictionary region names with polygons
    """
    with open(geojson_file, encoding="utf-8") as file:
        geo = json.load(file)

    polygons = {}

    for feature in geo["features"]:
        region_name = feature["properties"]["NAME"]

        # Work on a copy because fix_shape() may modify dictionaries.
        geometry = copy.deepcopy(feature["geometry"])

        # Convert the GeoJSON geometry to Shapely first.
        polygon = shape(geometry)

        # Fix antimeridian and polar geometries.
        #
        # great_circle=True makes meridian intersections follow
        # spherical geometry rather than simple Cartesian geometry.
        fixed_geometry = fix_shape(
            geometry,
            great_circle=True,
            fix_winding=True,
        )

        polygon = shape(fixed_geometry)
        # Store fixed geometry for diagnostic plotting.
        polygons[region_name] = polygon

    # ----------------------------------------------------------
    # Add global region from 60S to 60N
    # ----------------------------------------------------------

    polygons["Global_60S_60N"] = Polygon([
        (-180.0, -60.0),
        ( 180.0, -60.0),
        ( 180.0,  60.0),
        (-180.0,  60.0),
        (-180.0, -60.0),
    ])

    return polygons


def get_surface_ensemble_mean(ds, variable="thetao",
                              lon_var="nav_lon",
                              lat_var="nav_lat"):

    t0 = time.perf_counter()
    var_mean = (
        ds[variable]
        .astype(np.float32)
        .mean(dim="ens")
    )
    elapsed = time.perf_counter() - t0
    print(
        f"Ensemble mean computed in {elapsed:.3f} s"
    )


    return var_mean


def open_zarr(store, url="https://s3.waw3-1.cloudferro.com"):

    fs = s3fs.S3FileSystem(
        client_kwargs={
            "endpoint_url": url
        },
        anon=True,
        max_concurrency=1,
        default_block_size=16 * 1024 * 1024,
    )

    if not hasattr(store, "_opened_zarr"):
        _opened_zarr = {}

    if store not in _opened_zarr:

        mapper = s3fs.S3Map(
            root=f"s3://{store}",
            s3=fs
        )

        _opened_zarr[store] = xr.open_dataset(
            mapper,
            engine="zarr",
            consolidated=False,
            chunks={}
        )

    return _opened_zarr[store]

def build_zarr_list_ai(start_date, end_date, bucket_name="MOISICEEF",
                     endpoint_url="https://s3.waw3-1.cloudferro.com",
                     gridtype="3DT-thetao"):
    """
    Scan all forecast Zarr stores and build an index of their validity period.

    Returns
    -------
    index : list of dict
        Example:
        [
            {
                "store": "MOISICEEF/glo4-ens50_ng_1d-m_20251106-20251203_3DT-thetao_fcst_R20251106.zarr",
                "start": np.datetime64("2025-11-06"),
                "end": np.datetime64("2025-12-03"),
            },
            ...
        ]
    """
    start_date = datetime.strptime(str(start_date), "%Y%m%d")
    end_date = datetime.strptime(str(end_date), "%Y%m%d")

    fs = s3fs.S3FileSystem(
        client_kwargs={"endpoint_url": endpoint_url},
        anon=True,
    )
    print(endpoint_url)
    print(bucket_name)
    # List all Zarr forecast stores
    files = fs.ls(bucket_name)
    stores = sorted(
        f for f in files
        if f.endswith(".zarr") and f'{gridtype}' in f
    )
    candidates = []
    dateruns = []
    for store in sorted(stores):
        # Extract forecast run date RYYYYMMDD
        print(store)
        match_daterun = re.search(
            r"(\d{8})\.zarr$",
            store
        )
        if match_daterun:
            daterun = datetime.strptime(
                match_daterun.group(1),
                "%Y%m%d"
            )

            if start_date  <= daterun <= end_date:
                #print(
                #    f"Found Zarr for {run_date}: {store}"
                #    f"----------------------------------"
                #)
                candidates.append(store)
                daterun_str = daterun.strftime("%Y%m%d")
                dateruns.append(daterun_str)
    print(
        f"No Zarr found containing {daterun}"
    )
    return candidates, dateruns


def build_zarr_list(start_date, end_date, bucket_name="MOISICEEF",
                     endpoint_url="https://s3.waw3-1.cloudferro.com",
                     gridtype="3DT-thetao"):
    """
    Scan all forecast Zarr stores and build an index of their validity period.

    Returns
    -------
    index : list of dict
        Example:
        [
            {
                "store": "MOISICEEF/glo4-ens50_ng_1d-m_20251106-20251203_3DT-thetao_fcst_R20251106.zarr",
                "start": np.datetime64("2025-11-06"),
                "end": np.datetime64("2025-12-03"),
            },
            ...
        ]
    """

    start_date = datetime.strptime(str(start_date), "%Y%m%d")
    end_date = datetime.strptime(str(end_date), "%Y%m%d")

    fs = s3fs.S3FileSystem(
        client_kwargs={"endpoint_url": endpoint_url},
        anon=True,
    )
    # List all Zarr forecast stores
    files = fs.ls(bucket_name)

    stores = sorted(
        f for f in files
        if f.endswith(".zarr") and f'{gridtype}' in f
    )
    #print(start_date, end_date)
    candidates = []
    dateruns = []

    for store in sorted(stores):
        # Extract forecast run date RYYYYMMDD
        match_daterun = re.search(
            r"_R(\d{8})\.zarr$",
            store
        )
        match = re.search(
            r"_1d-m_(\d{8})-(\d{8})_",
            store
        )
        print(store)

        if match:
            start_date_zarr = datetime.strptime(
                match.group(1),
                "%Y%m%d"
            )

            end_date_zarr = datetime.strptime(
                match.group(2),
                "%Y%m%d"
            )
            print(
                f"Zarr period: {start_date_zarr} -> {end_date_zarr}"
            )
            run_date = datetime.strptime(
                match_daterun.group(1),
                "%Y%m%d"
            )
            # keep only runs after requested date
            if start_date  <= run_date <= end_date:
                #print(
                #    f"Found Zarr for {run_date}: {store}"
                #    f"----------------------------------"
                #)
                candidates.append(store)
                daterun_str = run_date.strftime("%Y%m%d")
                dateruns.append(daterun_str)

    print(
        f"No Zarr found containing {run_date}"
    )
    return candidates, dateruns



def chardate2datetime(cdaylist):
        outime = []
        for cday in cdaylist :
                try :
                        dB = dt.datetime.strptime(cday,'%Y%m%d')
                except Exception:
                    pass
                try :
                        dB = dt.datetime.strptime(cday,'%d %m %Y')
                except Exception:
                    pass
                try :
                        dB = dt.datetime.strptime(cday,'%Y %m %d')
                except Exception:
                    pass

                try :
                    outime.append(dB)
                except Exception:
                        print('Unknown date format : %s' %cday)
                        sys.exit(1)
        return outime

def char_period(cdate1,cdate2) :

    """
Returns a character-days list of the days contained in period given  \n
by the two input dates \n
output date format is YYYYMMDD \n\
warning : input date format should be YYYYMMDD
    """

    rdtdates = chardate2datetime([cdate1,cdate2])
    if rdtdates[0] == rdtdates[1] :
        return [cdate1]

    cda_dateout   = []
    rdt      = rdtdates[0]
    while rdt <= rdtdates[1] :
        cda_dateout.append(rdt.strftime('%Y%m%d'))
        rdt += dt.timedelta(1)

    return cda_dateout


def datenow() :
    date_now = dt.datetime.now()
    if date_now.month == 1 :
        cl_start_date = str(date_now.year-1)+"1201"
        cl_end_date = str(date_now.year)+"0101"
    elif date_now.month < 10 :
        cl_start_date = str(date_now.year)+"0"+str(date_now.month-1)+"01"
        cl_end_date = str(date_now.year)+"0"+str(date_now.month)+"01"
    elif date_now.month == 10 :
        cl_start_date = str(date_now.year)+"0"+str(date_now.month-1)+"01"
        cl_end_date = str(date_now.year)+str(date_now.month)+"01"
    else :
        cl_start_date = str(date_now.year)+str(date_now.month-1)+"01"
        cl_end_date = str(date_now.year)+str(date_now.month)+"01"
    return cl_start_date, cl_end_date


def save_stats_to_netcdf(results_stats, lead_times, depth_labels, output_path):

    ds_out = xr.Dataset()

    for var, stats in results_stats.items():
        tab_rmsd = stats['rmsd']
        tab_cumul_sq_diff = stats['sq_diff_cumul']
        tab_n_obs = stats['nb_obs']

        if var in ['SST', 'SLA', 'aice', 'DRIFTER_filtr', 'DRIFTER']:  # 2D vars
            dims = ['leadtime']
            coords = {'leadtime': lead_times}
            ds_out[f'{var}_rmsd'] = xr.DataArray(tab_rmsd, dims=dims, coords=coords)
            ds_out[f'{var}_sq_diff_cumul'] = xr.DataArray(tab_cumul_sq_diff, dims=dims, coords=coords)
            ds_out[f'{var}_nb_obs'] = xr.DataArray(tab_n_obs, dims=dims, coords=coords)

        else:  # 3D vars like temperature, salinity (index 0, 1)
            dims = ['leadtime', 'depth_bin']
            variable_names = ['temperature', 'salinity']
            coords = {
                'leadtime': lead_times,
                'depth_bin': depth_labels,  # You could also use mid-depths or similar
            }
            for ind_var, variable in enumerate(variable_names):
                ds_out[f'{variable}_rmsd'] = xr.DataArray(tab_rmsd[:, :, ind_var], dims=dims, coords=coords)
                ds_out[f'{variable}_sq_diff_cumul'] = xr.DataArray(tab_cumul_sq_diff[:, :, ind_var], dims=dims, coords=coords)
                ds_out[f'{variable}_nb_obs'] = xr.DataArray(tab_n_obs[:, :, ind_var], dims=dims, coords=coords)
    ds_out.to_netcdf(output_path)


def save_metrics_to_netcdf(tab_cumul_sq_diff,
                           tab_cumul_bias,
                           tab_n_obs,
                           tab_bias_daily,
                           tab_rmsd_daily,
                           tab_n_obs_daily,
                           lead_times,
                           output_path):
    """
    Save computed metrics to a NetCDF file with lead time as coordinate.

    Parameters
    ----------
    tab_cumul_sq_diff : np.ndarray
        Array of cumulative squared differences.
    tab_cumul_bias: np.ndarray
        Array of cumulative bias.
    tab_n_obs : np.ndarray
        Array of number of valid observations.
    tab_bias_daily : array-like
        Daily bias values. Expected shape:
        (n_leadtimes, nbdays).
    tab_rmsd_daily : array-like
        Daily RMSD values. Expected shape:
        (n_leadtimes, nbdays).
    tab_n_obs_daily : array-like
        Daily number of valid observations. Expected shape:
        (n_leadtimes, nbdays).
    lead_times : list or np.ndarray
        The lead times (coordinate).
    output_path : str
        Path to save the output NetCDF file.
    """

    # Convert daily lists to 2D arrays
    # Shape: (leadtime, nbdays)
    tab_bias_daily = np.asarray(tab_bias_daily, dtype=float)
    tab_rmsd_daily = np.asarray(tab_rmsd_daily, dtype=float)
    tab_n_obs_daily = np.asarray(tab_n_obs_daily, dtype=float)

    # Number of days
    nbdays = tab_bias_daily.shape[1]

    # Number of leadtimes
    n_leadtimes = len(lead_times)

    # -----------------------------
    # Global metrics
    # -----------------------------

    da_cumul = xr.DataArray(
        data=tab_cumul_sq_diff,
        coords={"leadtime": lead_times},
        dims=["leadtime"],
        name="cumul_squared_diff"
    )

    da_cumul_bias = xr.DataArray(
        data=tab_cumul_bias,
        coords={"leadtime": lead_times},
        dims=["leadtime"],
        name="cumul_bias"
    )

    da_nobs = xr.DataArray(
        data=tab_n_obs,
        coords={"leadtime": lead_times},
        dims=["leadtime"],
        name="cumul_n_obs"
    )

    # -----------------------------
    # Daily metrics
    # -----------------------------

    da_bias_daily = xr.DataArray(
        data=tab_bias_daily,
        coords={
            "leadtime": lead_times,
            "nbdays": np.arange(nbdays),
        },
        dims=["leadtime", "nbdays"],
        name="bias_daily",
    )

    da_rmsd_daily = xr.DataArray(
        data=tab_rmsd_daily,
        coords={
            "leadtime": lead_times,
            "nbdays": np.arange(nbdays),
        },
        dims=["leadtime", "nbdays"],
        name="rmsd_daily",
    )

    da_nobs_daily = xr.DataArray(
        data=tab_n_obs_daily,
        coords={
            "leadtime": lead_times,
            "nbdays": np.arange(nbdays),
        },
        dims=["leadtime", "nbdays"],
        name="n_obs_daily",
    )

    # Combine into one Dataset
    ds = xr.Dataset({
        "cumul_squared_diff": da_cumul,
        "cumul_bias": da_cumul_bias,
        "n_obs": da_nobs,
        "bias_daily": da_bias_daily,
        "rmsd_daily": da_rmsd_daily,
        "n_obs_daily": da_nobs_daily,
    })

    # Save to NetCDF
    ds.to_netcdf(output_path)


#def save_metrics_to_netcdf_regional(
#    tab_cumul_sq_diff,
#    tab_cumul_bias,
#    tab_n_obs,
#    tab_rmsd_daily,
#    tab_bias_daily,
#    tab_n_obs_daily,
#    region_names,
#    lead_int,
#    output_file,
#    depth_names=None,
#):
#    """
#    Save forecast verification metrics to NetCDF.
#
#    2D case:
#        arrays: (region, leadtime)
#
#    3D case:
#        arrays: (region, depth, leadtime)
#    """
#
#    nregion = len(region_names)
#    nlead = len(lead_int)
#
#    is_3d = tab_cumul_sq_diff.ndim == 3
#
#    if is_3d:
#        ndepth = len(depth_names)
#
#        assert tab_cumul_sq_diff.shape == (
#            nregion,
#            ndepth,
#            nlead,
#        )
#
#        assert tab_cumul_bias.shape == (
#            nregion,
#            ndepth,
#            nlead,
#        )
#
#        assert tab_n_obs.shape == (
#            nregion,
#            ndepth,
#            nlead,
#        )
#
#        # Global RMSD and BIAS from cumulative statistics
#        tab_rmsd = np.full(
#            (nregion, ndepth, nlead),
#            np.nan,
#        )
#
#        tab_bias = np.full(
#            (nregion, ndepth, nlead),
#            np.nan,
#        )
#
#        valid = tab_n_obs > 0
#
#        tab_rmsd[valid] = np.sqrt(
#            tab_cumul_sq_diff[valid]
#            / tab_n_obs[valid]
#        )
#
#        tab_bias[valid] = (
#            tab_cumul_bias[valid]
#            / tab_n_obs[valid]
#        )
#
#        ds = xr.Dataset(
#            data_vars={
#                "rmsd": (
#                    ("region", "depth", "leadtime"),
#                    tab_rmsd,
#                ),
#                "bias": (
#                    ("region", "depth", "leadtime"),
#                    tab_bias,
#                ),
#                "cumul_sq_diff": (
#                    ("region", "depth", "leadtime"),
#                    tab_cumul_sq_diff,
#                ),
#                "cumul_bias": (
#                    ("region", "depth", "leadtime"),
#                    tab_cumul_bias,
#                ),
#                "n_obs": (
#                    ("region", "depth", "leadtime"),
#                    tab_n_obs,
#                ),
#            },
#            coords={
#                "region": region_names,
#                "depth": depth_names,
#                "leadtime": lead_int,
#            },
#        )
#
#        # Daily statistics
#        ds["rmsd_daily"] = (
#            ("region", "depth", "leadtime", "day"),
#            _convert_daily_to_array(
#                tab_rmsd_daily,
#                nregion,
#                ndepth,
#                nlead,
#            ),
#        )
#
#        ds["bias_daily"] = (
#            ("region", "depth", "leadtime", "day"),
#            _convert_daily_to_array(
#                tab_bias_daily,
#                nregion,
#                ndepth,
#                nlead,
#            ),
#        )
#
#        ds["n_obs_daily"] = (
#            ("region", "depth", "leadtime", "day"),
#            _convert_daily_to_array(
#                tab_n_obs_daily,
#                nregion,
#                ndepth,
#                nlead,
#            ),
#        )
#
#    else:
#        assert tab_cumul_sq_diff.shape == (
#            nregion,
#            nlead,
#        )
#
#        # Global RMSD and BIAS from cumulative statistics
#        tab_rmsd = np.full(
#            (nregion, nlead),
#            np.nan,
#        )
#
#        tab_bias = np.full(
#            (nregion, nlead),
#            np.nan,
#        )
#
#        valid = tab_n_obs > 0
#
#        tab_rmsd[valid] = np.sqrt(
#            tab_cumul_sq_diff[valid]
#            / tab_n_obs[valid]
#        )
#
#        tab_bias[valid] = (
#            tab_cumul_bias[valid]
#            / tab_n_obs[valid]
#        )
#
#        ds = xr.Dataset(
#            data_vars={
#                "rmsd": (
#                    ("region", "leadtime"),
#                    tab_rmsd,
#                ),
#                "bias": (
#                    ("region", "leadtime"),
#                    tab_bias,
#                ),
#                "cumul_sq_diff": (
#                    ("region", "leadtime"),
#                    tab_cumul_sq_diff,
#                ),
#                "cumul_bias": (
#                    ("region", "leadtime"),
#                    tab_cumul_bias,
#                ),
#                "n_obs": (
#                    ("region", "leadtime"),
#                    tab_n_obs,
#                ),
#            },
#            coords={
#                "region": region_names,
#                "leadtime": lead_int,
#            },
#        )
#
#        # Daily statistics
#        ds["rmsd_daily"] = (
#            ("region", "leadtime", "day"),
#            _convert_daily_to_array_2d(
#                tab_rmsd_daily,
#                nregion,
#                nlead,
#            ),
#        )
#
#        ds["bias_daily"] = (
#            ("region", "leadtime", "day"),
#            _convert_daily_to_array_2d(
#                tab_bias_daily,
#                nregion,
#                nlead,
#            ),
#        )
#
#        ds["n_obs_daily"] = (
#            ("region", "leadtime", "day"),
#            _convert_daily_to_array_2d(
#                tab_n_obs_daily,
#                nregion,
#                nlead,
#            ),
#        )
#
#    ds.to_netcdf(output_file)

def mkdir(path):
    '''
        Create a directory, and parents if needed
    '''
    if not os.path.exists(path):
        os.makedirs(path)

def yaml_loader(path):
    try:
        with open(path, 'r') as file:
            patterns = yaml.safe_load(file)
        return patterns
    except Exception as e:
        raise(f"Failed to load patterns from {path}: {e}")
        sys.exit(1)

def loader(options):
    '''
                Input parameters settings
    '''

    tab_options ={}
    list_typemod = ['BIO','PHYS']
    tab_options['typemod'] = list_typemod
    list_config = ['FOAM', 'GIOPS', 'CMCC', 'CGOFS', 'BLK', 'PSY3V3R3',
                   'HYCOM_RTOFS', 'PSY4V2R2', 'PSY4V3R1', 'BIOMER4',
                   'FREEBIORYS2', 'NERSC', 'BIOMER4V2','ENSMEAN', 'GLO12',
                   'GLO12V4', 'GLO4', 'FOAM12']
    tab_options['config'] = list_config
    list_mask = ['basin','basin_pol','box','bins2d','bins2d_arc','bins2d_ant','bins4d']
    tab_options['fmt_mask'] = list_mask
    list_bilan, list_ascii, list_dailyoff, list_percent =  (['on','off'], ) * 4
    tab_options['bilan'], tab_options['fmt_ascii'], tab_options['daily_off'], tab_options['percent'] =  (['on','off'], ) * 4
    tab_options['day1'] = []
    tab_options['day2'] = []
    list_nblevel = ['50','75']
    tab_options['nb_levels'] = list_nblevel
    tab_conf ={}
    list_options = ['config','day1','day2','typemod','fmt_mask','bilan','fmt_ascii','daily_off','percent','nb_levels']
    ## Initialize dictionnary with None values
    tab_conf = dict.fromkeys(list_options)
    tab_conf['debug'] = False
    try:
        # the keyword
        cla_opts = getopt.getopt(options,['empid='])
        if len(cla_opts[1]) < 4 or len(cla_opts[1]) > 10:
            usage(len(cla_opts[1]))
            sys.exit()
        for ind,var in enumerate(range(len(cla_opts[1]))):
            if cla_opts[1][ind] == '-l':
                tab_conf['debug'] = True
            else:
                tab_conf[list_options[ind]] = cla_opts[1][ind]
                generic_test(tab_options[list_options[ind]],cla_opts[1][ind],list_options[ind])
        test_days(tab_conf['day1'], tab_conf['day2'])
        if len(cla_opts[1]) == 4:
            usage1()
        if len(cla_opts[1]) == 5:
            usage2()
        if len(cla_opts[1]) == 6:
            usage3()
        if len(cla_opts[1]) == 7:
            usage4()
        if len(cla_opts[1]) == 8:
            usage5()
        if len(cla_opts[1]) == 9:
            usage6()
        #if len(cla_opts[1]) == 10:
        #    usage7()

    except getopt.GetoptError as err:
        raise (f'Error {err} Missing options {keywords}')

    tab_conf['pbsworkdir'] = os.path.dirname(os.path.realpath(__file__))
    tab_conf['sub'] = tab_conf['pbsworkdir'] + '/../sub/'
    _DBFILE_ = tab_conf['pbsworkdir'] + "/../postraitement/python/compute_stats/cfg/global_params.cfg"
    db = load_db(_DBFILE_)
    tab_conf['dir_bin'] = db.get('PARAMS', 'py_env') + 'bin/'
    tab_conf['sub'] = f"{tab_conf['dirout']}/sub/"
    mkdir(tab_conf['sub'])

    return tab_conf

def generic_test(list_var,var,type_param):
    """
       Generic test for values
    """
    #print (f"{type_param=}")
    if type_param == 'day1' or type_param == 'day2':
        if not var:
            sys.exit(f'{type_param} is missing need {list_var}')
        isValiDate(var, type_param)
    else:
        if not var or var not in list_var:
            sys.exit(f'{type_param} is missing need {list_var}')


def convdatetime(var):
    """
       Convert date YYYYMMDD in a datetime value
    """
    try:
        year = var[0:4]
        month = var[4:6]
        day = var[6:8]
        datetime_val = datetime(int(year), int(month), int(day))
    except Exception as e:
        raise ValueError(f"Var {var} not a valid date for datetime , error {traceback.format_exc()}")
    return datetime_val

def test_days(day1, day2):
    """
        Test if a date2 > date 1
    """
    if convdatetime(day2) < convdatetime(day1):
        sys.exit(f"{day2} must be > at {day1}")

def isValiDate(var, type_param):
    """
        Test if a date is valid or not
    """
    isValiDate = True
    try:
        convdatetime(var)
    except ValueError:
        isValiDate = False
        sys.exit(f"Value {var} for {type_param} not a valid date")

    return isValiDate

def generate_date_list(start, end):
    # Convert strings to datetime objects
    start_date = datetime.strptime(start, "%Y%m%d")
    end_date = datetime.strptime(end, "%Y%m%d")
    # Generate list of dates between start_date and end_date
    date_list = [(start_date + timedelta(days=x)).strftime("%Y%m%d") for x in range((end_date - start_date).days + 1)]
    return date_list

def generate_date_list_week(start, end, delta=7):
    # Convert strings to datetime objects
    start_date = datetime.strptime(start, "%Y%m%d")
    end_date = datetime.strptime(end, "%Y%m%d")
    # Generate list of weekly dates
    date_list = []
    current_date = start_date
    while current_date <= end_date:
        date_list.append(current_date.strftime("%Y%m%d"))
        current_date += timedelta(days=delta)
    return date_list

from datetime import datetime, timedelta

def generate_nbdateslist(daterun, nb_forecasts):
    # Convert string to datetime object
    start_date = datetime.strptime(daterun, "%Y%m%d")

    # Generate the list of dates
    list_dates = [
        (start_date + timedelta(days=i)).strftime("%Y%m%d")
        for i in range(nb_forecasts)
    ]

    return list_dates

def create_launcher_multi(tab_conf, nbtasks='30', timecounter='06:00:00', batch='#SBATCH', nb_procs='2'):
    ## Create qsub job
    if tab_conf['fmt_mask'] == 'basin':
        typejob = 'timeserie'
    elif tab_conf['bilan'] is not None:
        typejob = 'bilan'
    elif tab_conf['percent'] != None:
        typejob = 'percent'
    else:
        typejob = 'others'
    _DBFILE_ = tab_conf['pbsworkdir'] + "/../postraitement/python/compute_stats/cfg/environment_"+tab_conf['config']+".cfg"
    EXE = os.path.join(tab_conf['pbsworkdir'],'../postraitement/python/compute_stats/exe_compute_stats_CMEMS_areas_multiprocess_2.py')
    tab_conf['dir_bin']
    day1  = tab_conf['day1']
    day2  = tab_conf['day2']
    datatype = tab_conf['typemod']
    fmt_mask = tab_conf['fmt_mask']
    bilan = tab_conf['bilan']
    fmt_ascii = tab_conf['fmt_ascii']
    daily_off = tab_conf['daily_off']
    percent = tab_conf['percent']
    nblevel = tab_conf['nb_levels']
    debug = tab_conf['debug']
    nb_process = int(nb_procs)*int(nbtasks)

    Jobfile = tab_conf['sub'] + 'Class4_post_' + typejob + '_'+ tab_conf['config'] + '_' +\
              tab_conf['day1'] + '_' + tab_conf['day2'] + '.sub'
    obFichier = open(Jobfile,'w+')
    obFichier.write('#!/usr/bin/env python'+'\n')
    obFichier.write(batch + ' -J '+'Class4_post_' + typejob + '_' + tab_conf['day1'] + '_' + tab_conf['day2'] + '\n')
    obFichier.write(batch + ' -e CLASS4_postjob_' + tab_conf['config'] + '_' +\
            tab_conf['day1'] + '_' + tab_conf['day2']+'_%j.e'+'\n')
    obFichier.write(batch + ' -o CLASS4_postjob_' + tab_conf['config'] + '_' +\
            tab_conf['day1'] + '_' + tab_conf['day2']+'_%j.o'+'\n')
    obFichier.write(batch + ' -p multi'+'\n')
    obFichier.write(batch + ' -N ' + nb_procs+'\n')
    obFichier.write(batch + ' -q qosmulti'+'\n')
    obFichier.write(batch + ' --exclusive'+'\n')
    obFichier.write(batch + ' --ntasks-per-node='+ nbtasks +'\n')
    obFichier.write(batch + ' --time='+ timecounter +'\n')
    obFichier.write('HDF5_USE_FILE_LOCKING = False'+'\n')
    obFichier.write('import os'+'\n')
    codexe = tab_conf['dir_bin']+"mpirun -np "+str(nb_process)+" "+tab_conf['dir_bin']+f"python {EXE} --day1={day1} --day2={day2} --cfg={_DBFILE_} --type={datatype} --fmt_mask={fmt_mask} --bilan={bilan} --fmt_ascii={fmt_ascii} --daily_off={daily_off} --percent={percent} --nblevel={nblevel} --debug={debug}"
    obFichier.write('codexe =' + "'" + codexe +"'"+'\n')
    obFichier.write('os.system(codexe)'+'\n')
    obFichier.close()

    return Jobfile


def launch_sbatch(Jobfile):

    SUBEXE="/usr/bin/sbatch"
    code_launch=f'{SUBEXE} {Jobfile}'
    args   = shlex.split(code_launch)
    #print(args)
    try :
        subprocess.run(args)
    except Exception as e:
        print (f'Launch {Jobfile} failed {e}')
        sys.exit(1)

def usage1():
    print(" *************************** DEFAULT CASE **************************")
    print(" ")
    print("     Case 1 Save stats computed at the daily time step over CMEMS areas    ")
    print("                     on netCDF format file                          ")
    print(" ")
    print(" ****************************************************************** ")

def usage2():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Case 2 Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/basin_pol/box/bins2d/bins4d            ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage3():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Case 3 Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( " ------------------------------------------------------------------------------")
    print( " " )

def usage4():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Case 4 Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage5():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Case 5 Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( "                                     &                                         ")
    print( "     -->   Activate/Deactivate save of stats at the daily time step  <--       ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage6():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Case 6 Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( "                                     &                                         ")
    print( "     -->   Activate/Deactivate save of stats at the daily time step  <--       ")
    print( "                                     &                                         ")
    print( "     -->   Activate bias and percentile computation for temperature  <--       ")
    print( "                             and salinity                                      ")
    print( " ------------------------------------------------------------------------------")
    print( " ")

def usage7():
    print( " ")
    print( " ------------------------------------------------------------------------------")
    print( "     -->   Case 7 Define the type of mask (default case : CMEMS areas)  <--           ")
    print( "                Available masks : basin/box/bins2d/bins4d                      ")
    print( "                                     &                                         ")
    print( "        -->   Activate/Deactivate save of stats computed over  <--             ")
    print( "                       the whole considered period                             ")
    print( "                                     &                                         ")
    print( "            -->   Activate/Deactivate save of stats on   <--                   ")
    print( "                          ASCII format file                                    ")
    print( "                                     &                                         ")
    print( "     -->   Activate/Deactivate save of stats at the daily time step  <--       ")
    print( "                                     &                                         ")
    print( "     -->   Activate bias and percentile computation for temperature  <--       ")
    print( "                             and salinity                                      ")
    print( "                                     &                                         ")
    print( "     -->   Change the number of considered levels to compute profile  <--      ")
    print( "                             T and S statistics                                ")
    print( " ------------------------------------------------------------------------------")
    print( " ")


def usage(nb_args):
    print ("              Incorrect number of Arguments"                 )
    print (f"   nb of arguments {nb_args}                           <-- ")
    print ("    arguments required                                  <-- ")
    print ("    Value1 = Config                                         ")
    print ("    Value2 = Day min                                        ")
    print ("    Value3 = Day max                                        ")
    print ("    Value4 = Type of data: BIO/PHYS"                         )
    print ("                                                            ")
    print (" -->              Optional argument                     <-- ")
    print ("    Value5 = Type of mask: basin/box/bins2d/bins4d          ")
    print ("    Value6 = Save global stats: on/off                      ")
    print ("    Value7 = Save stats on ASCII fmt files: on/off          ")
    print ("    Value8 = Save daily time step stats: on/off             ")
    print ("    Value9 = Compute misfit and percentile (profile): on/off")
    print ("    Value10 = Number of considered level profile            ")

def pull_names(name_data):
    """
        Convenient name retrieval function
    """
    names = []
    if isinstance(name_data, np.ma.masked_array):
        for letters in name_data:
            value = b''.join(letters.data).strip().decode("utf-8")
            #names.append(str(b''.join(letters.data)).strip())
            names.append(value)
    else:
        for letters in name_data:
            value = b''.join(letters).strip().decode("utf-8")
            names.append(value)
            #names.append(str(b''.join(letters)).strip())
    return names

def echeance(fcst, nf):
    """
       Find lead time
    """
    num_ech = np.where(fcst == nf)[0][0]
    if nf == 0:
        name_ech = 'Hindcast'
    else:
        name_ech = 'Forecast '+str(nf)+' hours'
    return num_ech, name_ech


def plot(iobs, rla_lonobs, rla_latobs, region, log):
    """
        Function to plot selected data
    """
    log.info("Plot region %s " %(region))
    area_names_arc = ['North Pole', 'Queen Elis Is', 'Beaufort Sea', 'Chuckchi Sea',
                      'Siberian Sea', 'Laptev Sea', 'Kara Sea', 'Barents Sea', 'Greenland Sea', 'Stheast Greenland', 'Bafin Bay',
                                                          'Hudson Bay', 'Labrador Sea', 'Bering Sea', 'Okhotsk Sea', ' Baltic Sea']
    area_names_ant = ['Weddel Sea', 'Southern Atlantic Ocean', 'Southern Indian Ocean', 'Southern West Pacific Ocean',
                      'Southern East Pacific Ocean', 'Ross Sea', 'Admundsen Sea', 'Bellingshausen Sea']

    rla_lonobs =  np.where(rla_lonobs>180,rla_lonobs-360,rla_lonobs)
    value = rla_lonobs[:].copy()
    value[:] = 1.0
    lon_inter = 20
    lat_inter = 20
    zone = "GLO"
    proj = "cyl_pac"
    if region in area_names_arc:
        pass
    if region in area_names_ant:
        pass
    #colormap = plt.cm.coolwarm
    #titre = 'Points in '+region+" with matplotlib meth"
    #outputfile = "Selected_points_"+region+".png"
    #colormap = plt.cm.coolwarm
    #cmin = 0
    #cmax = 1
    #dpi = 75
    #font = 16
    #dot_size = 2.0
    #log.info("Plot Map")
    #Plot_map(rla_lonobs[iobs].tolist(), rla_latobs[iobs].tolist(), zone, lon_inter, lat_inter, proj,\
    #        dpi, font).scatter_val(value[iobs].tolist(), colormap, cmin, cmax, dot_size, titre, outputfile)

def compute_last_day_month(y,m):
    return (dt.date(y+int(m/12),m%12+1,1)-dt.date(y,m,1)).days

def find_index_month(date):
    dateval = pd.to_datetime(date)
    index = dateval.month
    return index

def create_listdate(date1, date2):
    list_date = []
    valeurj = date1
    while valeurj >= date1  and valeurj <= date2:
        dateval = str(valeurj)
        list_date.append(dateval)
        valeurj = valeurj.goforward(1)
    return list_date

def create_leadtime(param_dict, variable):
    list_keys = {}
    list_keys_values = []
    list_uniq = ['best_estimate', 'climatology', 'bathy', 'clim_curr', 'bathymetrie', 'smoc','tides', 'stokes']
    list_uniq2 = ['stokes_fcst', 'smoc_fcst']
    list_var_curr = ['DRIFTER_filtr','DRIFTER']
    lead_int = param_dict['lead_int']
    if param_dict['cl_typemod'].lower() == 'smoc':
        lead_time = param_dict['lead_time_curr']
    else:   
        lead_time = param_dict['lead_time']
    for lead in lead_time:
        if lead in list_uniq:
            list_int = [0]
        elif lead in list_uniq2:
            list_int = param_dict['lead_int2']
        else:
            list_int = lead_int
        for int_val in list_int:
            keyvalue = f'{lead}-{int_val}'
            list_keys_values.append(keyvalue)
    list_keys['keyvalues'] = list_keys_values
    return list_keys

def create_dict(date1, date2, lead_time, lead_int):
    list_keys = {}
    valeurj = date1
    list_keys_values = []
    list_uniq = ['best_estimate', 'climatology', 'bathymetrie']
    while valeurj >= date1  and valeurj <= date2:
        dateval = str(valeurj)
        for lead in lead_time:
            if lead in list_uniq:
                list_int = [0]
            else:
                list_int = lead_int
            for int_val in list_int:
                keyvalue = f'{dateval}-{lead}-{int_val}'
                list_keys_values.append(keyvalue)
        valeurj = valeurj.goforward(1)
    list_keys['keyvalues'] = list_keys_values
    return list_keys



def date_range(start_date, end_date, increment, period):
    result = []
    nxt = start_date
    delta = relativedelta(**{period:increment})
    while nxt <= end_date:
        result.append(nxt)
        nxt += delta
    return result

def split_year_into_months(year):
    months = []
    for month in range(1, 13):
        first_day = datetime(year, month, 1)
        if month == 12:
            last_day = datetime(year + 1, 1, 1) - timedelta(days=1)
        else:
            last_day = datetime(year, month + 1, 1) - timedelta(days=1)
        months.append((first_day.strftime('%Y%m%d'), last_day.strftime('%Y%m%d')))
    return months

def get_nodes(list_files, log, np_max=8):
    max_cores = cpu_count()
    log.debug(f"Number of cores {max_cores}")
    #outer_procs = min(len(list_files), max_cores // 6 or 1)  # ~6 processes max
    #inner_threads = max(1, max_cores // outer_procs)
    np_max = np_max
    #outer_procs = min(len(input_list_files), max(1, max_cores // 8))  # low outer processes
    outer_procs = min(len(list_files), max(1, max_cores // np_max))  # low outer processes
    inner_threads = max(1, max_cores // outer_procs)  # threads per obs
    log.debug(f"CPU allocation: {outer_procs} processes × {inner_threads} threads")
    #num_cores = min(len(input_list_files), max(1, cpu_count() // 6))
    return outer_procs, inner_threads

import numpy as np
import xarray as xr


def _convert_daily_to_array_2d(
    values,
    nregion,
    nlead,
):
    """
    Convert daily statistics from:

        values[region][leadtime][day]

    to:

        (region, leadtime, day)
    """

    max_days = max(
        (
            len(values[iregion][ilead])
            for iregion in range(nregion)
            for ilead in range(nlead)
        ),
        default=0,
    )

    result = np.full(
        (nregion, nlead, max_days),
        np.nan,
        dtype=float,
    )

    for iregion in range(nregion):
        for ilead in range(nlead):

            data = values[iregion][ilead]

            if data:
                result[
                    iregion,
                    ilead,
                    :len(data),
                ] = data

    return result


def _convert_daily_to_array_3d(
    values,
    nregion,
    ndepth,
    nlead,
):
    """
    Convert daily statistics from:

        values[region][depth][leadtime][day]

    to:

        (region, depth, leadtime, day)
    """

    max_days = max(
        (
            len(values[iregion][idepth][ilead])
            for iregion in range(nregion)
            for idepth in range(ndepth)
            for ilead in range(nlead)
        ),
        default=0,
    )

    result = np.full(
        (nregion, ndepth, nlead, max_days),
        np.nan,
        dtype=float,
    )

    for iregion in range(nregion):
        for idepth in range(ndepth):
            for ilead in range(nlead):

                data = values[
                    iregion
                ][
                    idepth
                ][
                    ilead
                ]

                if data:
                    result[
                        iregion,
                        idepth,
                        ilead,
                        :len(data),
                    ] = data

    return result


def save_metrics_to_netcdf_regional(
    tab_cumul_sq_diff,
    tab_cumul_bias,
    tab_n_obs,
    tab_rmsd_daily,
    tab_bias_daily,
    tab_n_obs_daily,
    region_names,
    lead_int,
    output_file,
    depth_names=None,
):
    """
    Save forecast verification metrics to NetCDF.

    2D case
    -------
    Cumulative arrays:
        (region, leadtime)

    Daily arrays:
        (region, leadtime, day)

    3D case
    -------
    Cumulative arrays:
        (region, depth, leadtime)

    Daily arrays:
        (region, depth, leadtime, day)

    For the 3D case, the last depth category is expected to be
    "Total".
    """

    nregion = len(region_names)
    nlead = len(lead_int)

    # Convert to numpy arrays
    tab_cumul_sq_diff = np.asarray(tab_cumul_sq_diff)
    tab_cumul_bias = np.asarray(tab_cumul_bias)
    tab_n_obs = np.asarray(tab_n_obs)

    # ---------------------------------------------------------
    # Determine 2D / 3D case
    # ---------------------------------------------------------

    is_3d = tab_cumul_sq_diff.ndim == 3

    # =========================================================
    # 3D CASE
    # =========================================================

    if is_3d:

        if depth_names is None:
            raise ValueError(
                "depth_names must be provided for the 3D case."
            )

        ndepth = len(depth_names)

        # Check shapes
        expected_shape = (
            nregion,
            ndepth,
            nlead,
        )

        if tab_cumul_sq_diff.shape != expected_shape:
            raise ValueError(
                "tab_cumul_sq_diff has shape "
                f"{tab_cumul_sq_diff.shape}, "
                f"expected {expected_shape}"
            )

        if tab_cumul_bias.shape != expected_shape:
            raise ValueError(
                "tab_cumul_bias has shape "
                f"{tab_cumul_bias.shape}, "
                f"expected {expected_shape}"
            )

        if tab_n_obs.shape != expected_shape:
            raise ValueError(
                "tab_n_obs has shape "
                f"{tab_n_obs.shape}, "
                f"expected {expected_shape}"
            )

        # -----------------------------------------------------
        # Compute global RMSD and BIAS
        # -----------------------------------------------------

        tab_rmsd = np.full(
            expected_shape,
            np.nan,
            dtype=float,
        )

        tab_bias = np.full(
            expected_shape,
            np.nan,
            dtype=float,
        )

        valid = tab_n_obs > 0

        tab_rmsd[valid] = np.sqrt(
            tab_cumul_sq_diff[valid]
            / tab_n_obs[valid]
        )

        tab_bias[valid] = (
            tab_cumul_bias[valid]
            / tab_n_obs[valid]
        )

        # -----------------------------------------------------
        # Convert daily statistics
        # -----------------------------------------------------

        rmsd_daily = _convert_daily_to_array_3d(
            tab_rmsd_daily,
            nregion,
            ndepth,
            nlead,
        )

        bias_daily = _convert_daily_to_array_3d(
            tab_bias_daily,
            nregion,
            ndepth,
            nlead,
        )

        n_obs_daily = _convert_daily_to_array_3d(
            tab_n_obs_daily,
            nregion,
            ndepth,
            nlead,
        )

        # -----------------------------------------------------
        # Create Dataset
        # -----------------------------------------------------

        ds = xr.Dataset(
            data_vars={
                "rmsd": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                    ),
                    tab_rmsd,
                ),

                "bias": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                    ),
                    tab_bias,
                ),

                "cumul_sq_diff": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                    ),
                    tab_cumul_sq_diff,
                ),

                "cumul_bias": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                    ),
                    tab_cumul_bias,
                ),

                "n_obs": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                    ),
                    tab_n_obs,
                ),

                "rmsd_daily": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                        "day",
                    ),
                    rmsd_daily,
                ),

                "bias_daily": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                        "day",
                    ),
                    bias_daily,
                ),

                "n_obs_daily": (
                    (
                        "regions",
                        "depth",
                        "leadtime",
                        "day",
                    ),
                    n_obs_daily,
                ),
            },

            coords={
                "regions": region_names,
                "depth": depth_names,
                "leadtime": lead_int,
                "day": np.arange(
                    rmsd_daily.shape[-1]
                ),
            },
        )

    # =========================================================
    # 2D CASE
    # =========================================================

    else:

        expected_shape = (
            nregion,
            nlead,
        )

        # Check shapes
        if tab_cumul_sq_diff.shape != expected_shape:
            raise ValueError(
                "tab_cumul_sq_diff has shape "
                f"{tab_cumul_sq_diff.shape}, "
                f"expected {expected_shape}"
            )

        if tab_cumul_bias.shape != expected_shape:
            raise ValueError(
                "tab_cumul_bias has shape "
                f"{tab_cumul_bias.shape}, "
                f"expected {expected_shape}"
            )

        if tab_n_obs.shape != expected_shape:
            raise ValueError(
                "tab_n_obs has shape "
                f"{tab_n_obs.shape}, "
                f"expected {expected_shape}"
            )

        # -----------------------------------------------------
        # Compute global RMSD and BIAS
        # -----------------------------------------------------

        tab_rmsd = np.full(
            expected_shape,
            np.nan,
            dtype=float,
        )

        tab_bias = np.full(
            expected_shape,
            np.nan,
            dtype=float,
        )

        valid = tab_n_obs > 0

        tab_rmsd[valid] = np.sqrt(
            tab_cumul_sq_diff[valid]
            / tab_n_obs[valid]
        )

        tab_bias[valid] = (
            tab_cumul_bias[valid]
            / tab_n_obs[valid]
        )

        # -----------------------------------------------------
        # Convert daily statistics
        # -----------------------------------------------------

        rmsd_daily = _convert_daily_to_array_2d(
            tab_rmsd_daily,
            nregion,
            nlead,
        )

        bias_daily = _convert_daily_to_array_2d(
            tab_bias_daily,
            nregion,
            nlead,
        )

        n_obs_daily = _convert_daily_to_array_2d(
            tab_n_obs_daily,
            nregion,
            nlead,
        )

        # -----------------------------------------------------
        # Create Dataset
        # -----------------------------------------------------

        ds = xr.Dataset(
            data_vars={
                "rmsd": (
                    (
                        "regions",
                        "leadtime",
                    ),
                    tab_rmsd,
                ),

                "bias": (
                    (
                        "regions",
                        "leadtime",
                    ),
                    tab_bias,
                ),

                "cumul_sq_diff": (
                    (
                        "regions",
                        "leadtime",
                    ),
                    tab_cumul_sq_diff,
                ),

                "cumul_bias": (
                    (
                        "regions",
                        "leadtime",
                    ),
                    tab_cumul_bias,
                ),

                "n_obs": (
                    (
                        "regions",
                        "leadtime",
                    ),
                    tab_n_obs,
                ),

                "rmsd_daily": (
                    (
                        "regions",
                        "leadtime",
                        "day",
                    ),
                    rmsd_daily,
                ),

                "bias_daily": (
                    (
                        "regions",
                        "leadtime",
                        "day",
                    ),
                    bias_daily,
                ),

                "n_obs_daily": (
                    (
                        "regions",
                        "leadtime",
                        "day",
                    ),
                    n_obs_daily,
                ),

            },

            coords={
                "regions": region_names,
                "leadtime": lead_int,
                "day": np.arange(
                    rmsd_daily.shape[-1]
                ),
            },
        )

    # =========================================================
    # Global attributes
    # =========================================================

    ds.attrs["description"] = (
        "Regional forecast verification statistics"
    )

    ds.attrs["statistics"] = (
        "RMSD and BIAS computed from cumulative statistics"
    )

    ds.attrs["region_dimension"] = (
        "Statistics are provided independently for each region"
    )

    if is_3d:
        ds.attrs["depth_dimension"] = (
            "Statistics are provided for depth layers and Total"
        )

    # =========================================================
    # Save
    # =========================================================

    ds.to_netcdf(
        output_file,
        mode="w",
    )

    return ds
