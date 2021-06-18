import sys
import numpy as np
import netCDF4
from netCDF4 import Dataset
import utilities
import param.Def_param_bulletin as params
import xarray as xr
import dask

__version__ = 0.1
__date__ = "February 2019"
__authors__ = "C.REGNIER & C.SZCZYPTA" 


def read_mask_polar(params_conf):

    basin_mask_arc = params_conf['db'].get('NETCDF', 'file_basin_arc')
    basin_mask_ant = params_conf['db'].get('NETCDF', 'file_basin_ant')
    file_areamask = [basin_mask_arc, basin_mask_ant]
    file_areamask_arc, file_areamask_ant = file_areamask
    nc = netCDF4.Dataset(file_areamask_arc, 'r')
    rla_mask_arc = nc.variables['mask'][:, :]
    rla_lonmask_arc = nc.variables['longitude'][:, :]
    rla_lonmask_nan_arc = np.ma.filled(rla_lonmask_arc, np.nan)
    rla_latmask_arc = nc.variables['latitude'][:, :]
    nc.close()
    nc = netCDF4.Dataset(file_areamask_ant, 'r')
    rla_mask_ant = nc.variables['mask'][:, :]
    rla_lonmask_ant = nc.variables['longitude'][:, :]
    rla_lonmask_nan_ant = np.ma.filled(rla_lonmask_ant, np.nan)
    rla_latmask_ant = nc.variables['latitude'][:, :]
    nc.close()
    CMEMS_area = True
    rla_maskvalues = []

    area_names_arc = ['North Pole', 'Queen Elis Is', 'Beaufort Sea', 'Chuckchi Sea',
                      'Siberian Sea', 'Laptev Sea', 'Kara Sea', 'Barents Sea', 'Greenland Sea', 'Stheast Greenland', 'Bafin Bay',
                      'Hudson Bay', 'Labrador Sea', 'Bering Sea', 'Okhotsk Sea', ' Baltic Sea']
    area_names_ant = ['Weddel Sea', 'Southern Atlantic Ocean', 'Southern Indian Ocean', 'Southern West Pacific Ocean',
                      'Southern East Pacific Ocean', 'Ross Sea', 'Admundsen Sea', 'Bellingshausen Sea']
    params_conf['area_name'] = area_names_arc + area_names_ant
    maskvalues = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
                  13, 14, 15, 16, 20, 21, 22, 23, 24, 25, 26, 27]
    for area_mask in range(len(params_conf['area_name'])):
        if area_mask < 16:
            #print ("Arctic region")
            rla_mask = rla_mask_arc
        else:
            #print ("Antarctic region")
            rla_mask = rla_mask_ant
        rla_maskvalues.append(maskvalues[area_mask])
    cla_areaname = np.chararray(len(params_conf['area_name']), itemsize=25)
    cla_areaini = np.chararray(len(params_conf['area_name']), itemsize=25)
    for indice, i in enumerate(params_conf['area_name']):
        cla_areaname[indice] = i
        cla_areaini[indice] = i
    cla_area = list(cla_areaini)
    params_conf['CMEMS_area'] = CMEMS_area
    params_conf['cla_area'] = cla_area
    params_conf['cla_area_names'] = cla_areaname
    params_conf['cla_areaini'] = cla_areaini
    params_conf['maskvalues'] = maskvalues

    return params_conf, rla_mask_arc, rla_mask_ant, rla_maskvalues, rla_lonmask_nan_arc,\
        rla_latmask_arc, rla_lonmask_nan_ant,  rla_latmask_ant


def read_mask(params_conf):

    cla_areaname = params.cla_areasattr
    cla_areaini = params.liste_zone
    file_areamask = params_conf['db'].get(
        'NETCDF', 'file_' + params_conf['fmt_mask'])
    nc = netCDF4.Dataset(file_areamask, 'r')
    rla_mask = nc.variables['mask'][:]
    rla_lonmask = nc.variables['longitude'][:]
    rla_latmask = nc.variables['latitude'][:]
    rla_lonmask_nan = np.ma.filled(rla_lonmask, np.nan)
    rla_lonmask_nan_shift = np.where(
        rla_lonmask_nan < 0, rla_lonmask_nan+360, rla_lonmask_nan)
    if 'area_names' in nc.variables:
        rla_name = nc.variables['area_names'][:]
        area_name = utilities.pull_names(rla_name)
        cla_area = list(cla_areaini)
        cla_area = [var.decode("utf-8") for var in cla_area]
        CMEMS_area = True
        rla_maskvalues = None
    else:
        area_name = [0]
        fmt_ascii = 0
        CMEMS_area = False
        rla_maskvalues = np.unique(rla_mask)
        rla_maskvalues = np.delete(
            rla_maskvalues, np.where(rla_maskvalues == 0))
        rla_maskvalues = np.delete(rla_maskvalues, np.where(
            np.isnan(rla_maskvalues) == True))
        cla_area = list(np.arange((len(np.array(rla_maskvalues)))))
    nc.close()
    params_conf['CMEMS_area'] = CMEMS_area
    params_conf['cla_area'] = cla_area
    params_conf['cla_area_names'] = cla_areaname
    params_conf['cla_areaini'] = cla_areaini
    params_conf['area_name'] = area_name

    return params_conf, rla_mask, rla_maskvalues, rla_lonmask_nan, rla_latmask


def mask2(params_conf):

    try:
        prefix = 'product_quality_stats_'
        rla_lonmask_arc = None
        rla_lonmask_ant = None
        rla_latmask_arc = None
        rla_latmask_ant = None
        rla_latmask = None
        rla_lonmask = None
        rla_mask = None
        rla_mask_arc = None
        rla_mask_ant = None
        if params_conf['fmt_mask'] == 'basin_pol':
            dirout = params_conf['dirNCout']
            prefix = 'product_quality_stats_polar_'
            params_conf, rla_mask_arc, rla_mask_ant, rla_maskvalues, \
                rla_lonmask_arc, rla_latmask_arc, rla_lonmask_ant,\
                rla_latmask_ant = read_mask_polar(params_conf)
        else:
            params_conf, rla_mask, rla_maskvalues,\
                rla_lonmask, rla_latmask = read_mask(params_conf)
            if params_conf['fmt_mask'] == 'basin':
                dirout = params_conf['dirNCout']
            elif params_conf['fmt_mask'] == 'bins2d_arc':
                prefix = 'bins2d_product_quality_stats_NH_polar_' + \
                    params_conf['fmt_mask']
                dirout = params_conf['dirBOXout']
            elif params_conf['fmt_mask'] == 'bins2d_ant':
                prefix = 'bins2d_product_quality_stats_SH_polar_' + \
                    params_conf['fmt_mask']
                dirout = params_conf['dirBOXout']
            else:
                dirout = params_conf['dirBOXout']
    except:
        print("Error input grid not find:", sys.exc_info()[0])
        raise
    params_conf['dirout'] = dirout
    params_conf['prefix_fileout'] = prefix

    return params_conf, rla_mask, rla_maskvalues, rla_mask_arc, rla_mask_ant, rla_lonmask,\
        rla_latmask, rla_lonmask_arc, rla_latmask_arc, rla_lonmask_ant, rla_latmask_ant


def mask(fmt_mask, basin_mask, box_mask, bins025d_mask, bins05d_mask, bins1d_mask,
         bins2d_mask, bins4d_mask, dirNCout, dirBOXout):

    if fmt_mask == 'basin':
        file_areamask = basin_mask
        dirout = dirNCout
        prefix = 'product_quality_stats_'
    elif fmt_mask == 'basin_pol':
        file_areamask = basin_mask
        dirout = dirNCout
        prefix = 'product_quality_stats_ice_'
    elif fmt_mask == 'box':
        file_areamask = box_mask
        dirout = dirBOXout
        prefix = 'box_quality_stats_'
    elif fmt_mask == 'bins05d':
        file_areamask = bins05d_mask
        dirout = dirBOXout
        prefix = 'bins05d_quality_stats_'
    elif fmt_mask == 'bins025d':
        file_areamask = bins025d_mask
        dirout = dirBOXout
        prefix = 'bins025d_quality_stats_'
    elif fmt_mask == 'bins1d':
        file_areamask = bins1d_mask
        dirout = dirBOXout
        prefix = 'bins1d_quality_stats_'
    elif fmt_mask == 'bins2d':
        file_areamask = bins2d_mask
        dirout = dirBOXout
        prefix = 'bins2d_quality_stats_'
    elif fmt_mask == 'bins4d':
        file_areamask = bins4d_mask
        dirout = dirBOXout
        prefix = 'bins4d_quality_stats_'

    return file_areamask, dirout, prefix

def read_pos(filename, log):
    try:
        nc = netCDF4.Dataset(filename,'r')
        variable = 'nav_lon'
        rla_lon = nc.variables[variable][:,:]
        variable = 'nav_lat'
        rla_lat = nc.variables[variable][:,:]
    except:
        log.info ('pb lecture coordinates')

    return rla_lon,rla_lat


def read_pos_reg(filename):
    nc = netCDF4.Dataset(filename,'r')
    variable = 'longitude'
    rla_lon = nc.variables[variable][:]
    variable = 'latitude'
    rla_lat = nc.variables[variable][:]
    return rla_lon,rla_lat

def read_pos_clim(filename):
    nc = netCDF4.Dataset(filename,'r')
    variable = 'Lon'
    rla_lon = nc.variables[variable][:]
    variable = 'Lat'
    rla_lat = nc.variables[variable][:]
    return rla_lon,rla_lat

def read_drifter_pos(file):
    ncdata = xr.open_dataset(file)
    lon = ncdata['LONGITUDE'].values
    lat = ncdata['LATITUDE'].values
    ncdata.close()
    return lon, lat

def read_drifter(file):
    ncdata = xr.open_dataset(file)
    #variables = ncdata.data_vars
    nc = netCDF4.Dataset(file, 'r')
    variables = nc.variables
    ll_var = False
    if 'EWCT' and 'NSCT' in variables.keys():
        ll_var = True
        u = ncdata['EWCT'].values
        v = ncdata['NSCT'].values
        u_qc = ncdata['EWCT_QC'].values
        v_qc = ncdata['NSCT_QC'].values
    else:
        u = None ; v = None
        u_qc = None ; v_qc = None
    if 'WSTN_MODEL' and 'WSTE_MODEL' in variables.keys():
        wind_v = ncdata['WSTN_MODEL'].values
        wind_u = ncdata['WSTE_MODEL'].values
    else:
        wind_u = None ; wind_v = None
    if 'DEPH' in variables.keys():
        depth = ncdata['DEPH'].values
        depth_qc = ncdata['DEPH_QC'].values
    elif 'depth' in variables.keys():
        depth = ncdata['depth'].values
        depth_qc = ncdata['depth_qc'].values
    elif 'PRES' in variables.keys():
        depth = ncdata['PRES'].values
        depth_qc = ncdata['PRES_QC'].values
    else:
        print ('Missing Values DEPH or PRES or depth')
        sys.exit(1)
    if 'CURRENT_TEST' in variables.keys():
        current_test = ncdata['CURRENT_TEST'].values
        current_test_qc = ncdata['CURRENT_TEST_QC'].values
    else:
        current_test = None ; current_test_qc = None
    if 'POSITION_QC' in variables.keys():
        position_qc =  ncdata['POSITION_QC'].values
    else:
        position_qc = None
    if 'TIME_QC' in variables.keys():
        time_qc =  ncdata['TIME_QC'].values
    else:
        time_qc = None
    if 'DC_REFERENCE' in  variables.keys():
        dc_reference =  ncdata['DC_REFERENCE'].values
    else:
        dc_reference =  None
    if 'LONGITUDE' in variables.keys():
        lon = ncdata['LONGITUDE'].values
    elif 'longitude' in variables.keys():
        lon = ncdata['longitude'].values
    if 'LATITUDE' in variables.keys():
        lat = ncdata['LATITUDE'].values
    elif 'latitude' in variables.keys():
        lat = ncdata['latitude'].values
    if 'TIME' in variables.keys():
        time = ncdata['TIME'].values
    elif 'time' in variables.keys():
        time = ncdata['time'].values
    elif 'obs_time' in variables.keys():
        time = ncdata['obs_time'].values

    #lon_value = np.nanmean(lon)
    #lat_value = np.nanmean(lat)
    ncdata.close()
    return lon, lat, depth, depth_qc, time, u, v, ll_var,\
            u_qc, v_qc, wind_u, wind_v, current_test, current_test_qc,\
            position_qc, time_qc, dc_reference

def read_drifter_filt(file):
    lon, lat, depth, depth_qc, time, u, v, ll_var,\
            u_qc, v_qc, wind_u, wind_v, current_test, current_test_qc,\
            position_qc, time_qc, dc_reference = read_drifter(file)
    ncdata = xr.open_dataset(file)
    variables = ncdata.data_vars
    
    if 'LONGITUDE_FILTR' in variables.keys():
        lon = ncdata['LONGITUDE_FILTR'].values
    elif 'longitude_filtr' in variables.keys():
        lon = ncdata['longitude_filtr'].values
    if 'LATITUDE_FILTR' in variables.keys():
        lat = ncdata['LATITUDE_FILTR'].values
    elif 'latitude_filtr' in variables.keys():
        lat = ncdata['latitude_filtr'].values
    ll_var = False
    if 'EWCT_FILTR' and 'NSCT_FILTR' in variables.keys():
        ll_var = True
        u_filtr = ncdata['EWCT_FILTR'].values
        v_filtr = ncdata['NSCT_FILTR'].values
        u_filtr_qc = ncdata['EWCT_FILTR_QC'].values
        v_filtr_qc = ncdata['NSCT_FILTR_QC'].values
    elif 'observation_filtr':
        ll_var = True
        u_filtr = ncdata['observation_filtr'][:,0].values
        v_filtr = ncdata['observation_filtr'][:,1].values
        u_filtr_qc = ncdata['observation_filtr_qc'][:,0].values
        v_filtr_qc = ncdata['observation_filtr_qc'][:,1].values
    else:
        print ('Missing observations')
        sys.exit(1)
        u_filtr = None ; v_filtr = None
        u_filtr_qc = None ; v_filtr_qc = None
    return lon, lat, depth, depth_qc, time, u, v, u_filtr, v_filtr, ll_var,\
            u_qc, v_qc, u_filtr_qc, v_filtr_qc, wind_u, wind_v, current_test, current_test_qc,\
            position_qc, time_qc, dc_reference


def read_moor(file, log):
    """
       Read Mooring files
    """
    ncdata = xr.open_dataset(file)
    variables = ncdata.data_vars
    ll_temp = False
    if 'TEMP' in variables.keys():
        ll_temp = True
        temp = ncdata['TEMP']
        temp_qc = ncdata['TEMP_QC']
    else:
        temp = np.nan
        temp_qc = np.nan
    if 'DEPH' in ncdata.variables.keys():
        depth = ncdata['DEPH'][0]
        var_qc=[ var for var in ncdata.variables.keys() if var.startswith('DEP') and var.endswith('QC')] 
        depth_qc = ncdata[var_qc].values
    elif 'PRES' in variables.keys():
        depth = ncdata['PRES'][0]
        depth_qc = ncdata['PRES_QC'][0]
    else:
        log.info ('Missing Values DEPH or PRES')
        sys.exit(1)

    lon = ncdata['LONGITUDE']
    lat = ncdata['LATITUDE']
    time = ncdata['TIME'].values
    lon_value = np.nanmean(lon)
    lat_value = np.nanmean(lat)

    return lon_value, lat_value, depth, depth_qc, time, temp, ll_temp, temp_qc

def read_depth(filename):
    nc = netCDF4.Dataset(filename,'r')
    variable = 'deptht'
    rla_depth = nc.variables[variable][:]

    return rla_depth

def read_GODAE_profile(varname, filename):
    '''
       Read GODAE profile
    '''
    ncdata = xr.open_dataset(filename)
    variables = ncdata.data_vars
    depth = ncdata['depth'].values
    if varname == 'votemper':
        index = 0
    elif varname == 'vosaline':
        index = 1
    tab_hdct = ncdata['best_estimate'].values
    tab_hdct = tab_hdct[:,index,:]
    tab_fcst = ncdata['forecast'].values
    tab_fcst = tab_fcst[:,index,:,:]
    tab_pers = ncdata['persistence'].values
    tab_pers = tab_pers[:,index,:,:]
    observations = ncdata['observation'][:,index,:].values

    return depth, tab_hdct, tab_fcst, tab_pers, observations
