import sys
import numpy as np
import netCDF4
from netCDF4 import Dataset
import define_config
import param.Def_param_bulletin as params

# *****************************************
#           Autor: C.Szczypta
#          Date: Octobre 2018
# *****************************************



# **************************** Convenient name retrieval function ***************************************

def pull_names(name_data):
    names = []
    if isinstance(name_data, np.ma.masked_array):
        for letters in name_data:
            names.append((''.join(letters.data)).strip())
    else:
        for letters in name_data:
            names.append((''.join(letters)).strip())
    return names


def read_mask_polar(db):

    basin_mask_arc   = db.get('NETCDF','file_basin_arc' )
    basin_mask_ant   = db.get('NETCDF','file_basin_ant' )
    file_areamask = [basin_mask_arc, basin_mask_ant]
    file_areamask_arc, file_areamask_ant = file_areamask
    nc = netCDF4.Dataset(file_areamask_arc,'r')
    rla_mask_arc = nc.variables['mask'][:,:]
    rla_lonmask_arc = nc.variables['longitude'][:,:]
    rla_lonmask_nan_arc= np.ma.filled(rla_lonmask_arc, np.nan)
    rla_latmask_arc = nc.variables['latitude'][:,:]
    nc.close()
    nc = netCDF4.Dataset(file_areamask_ant,'r')
    rla_mask_ant = nc.variables['mask'][:,:]
    rla_lonmask_ant = nc.variables['longitude'][:,:]
    rla_lonmask_nan_ant= np.ma.filled(rla_lonmask_ant, np.nan)
    rla_latmask_ant = nc.variables['latitude'][:,:]
    nc.close()
    CMEMS_area = True
    rla_maskvalues = []
    for area_mask in range(len(area_name)):
        if area_mask < 16 :
            ##print ("Arctic region")
            rla_mask = rla_mask_arc
        else:
            ##print ("Antarctic region")
            rla_mask = rla_mask_ant
        rla_maskvalues.append(maskvalues[area_mask])

    area_names_arc=['North Pole', 'Queen Elis Is', 'Beaufort Sea', 'Chuckchi Sea', \
                    'Siberian Sea', 'Laptev Sea', 'Kara Sea', 'Barents Sea', 'Greenland Sea', 'Stheast Greenland', 'Bafin Bay',\
                    'Hudson Bay', 'Labrador Sea', 'Bering Sea', 'Okhotsk Sea',' Baltic Sea']
    area_names_ant=['Weddel Sea', 'Southern Atlantic Ocean', 'Southern Indian Ocean','Southern West Pacific Ocean',\
                    'Southern East Pacific Ocean', 'Ross Sea', 'Admundsen Sea', 'Bellingshausen Sea']
    area_name = area_names_arc + area_names_ant
    maskvalues=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 20, 21, 22, 23, 24, 25, 26, 27]
    cla_areaname = np.chararray(len(area_name), itemsize=25)
    cla_areaini = np.chararray(len(area_name), itemsize=25)
    for indice, i in enumerate(area_name):
        cla_areaname[indice] = i
        cla_areaini[indice] = i
    cla_area = list(cla_areaini)

    return rla_mask_arc, rla_mask_ant, rla_maskvalues, cla_areaname, cla_areaini, cla_area, rla_lonmask_nan_arc,\
             rla_latmask_arc, rla_lonmask_nan_ant,  rla_latmask_ant, CMEMS_area, area_name

def read_mask(db, fmt_mask):

    cla_areaname = params.cla_areasattr
    cla_areaini = params.liste_zone
    file_areamask = db.get('NETCDF','file_'+fmt_mask)
    nc = netCDF4.Dataset(file_areamask,'r')
    rla_mask = nc.variables['mask'][:]
    rla_lonmask = nc.variables['longitude'][:]
    rla_latmask = nc.variables['latitude'][:]
    rla_lonmask_nan= np.ma.filled(rla_lonmask, np.nan)
    rla_lonmask_nan_shift=np.where(rla_lonmask_nan<0,rla_lonmask_nan+360,rla_lonmask_nan)
    if 'area_names' in nc.variables:
        rla_name = nc.variables['area_names'][:]
        area_name = define_config.pull_names(rla_name)
        cla_area = list(cla_areaini)
        CMEMS_area = True
        rla_maskvalues =  None
    else:
        area_name = [0]
        fmt_ascii = 0
        CMEMS_area = False
        rla_maskvalues = np.unique(rla_mask)
        rla_maskvalues = np.delete(rla_maskvalues,np.where(rla_maskvalues==0))
        rla_maskvalues = np.delete(rla_maskvalues,np.where(np.isnan(rla_maskvalues)==True))
        cla_area = list(np.arange((len(np.array(rla_maskvalues)))))
    nc.close()

    return rla_mask, rla_maskvalues, cla_areaname, cla_areaini, cla_area, rla_lonmask_nan, rla_latmask, CMEMS_area, area_name


def mask2(fmt_mask, db, dirNCout, dirBOXout):

    try:
        prefix = 'product_quality_stats_'
        rla_lonmask_arc = None
        rla_lonmask_ant = None
        rla_latmask_arc = None
        rla_latmask_ant = None
        rla_latmask =  None
        rla_lonmask = None
        rla_mask = None
        rla_mask_arc = None
        rla_mask_ant = None
        if fmt_mask == 'basin_pol':
            dirout = dirNCout
            prefix = 'product_quality_stats_polar_'
            rla_mask_arc, rla_mask_ant, rla_maskvalues, cla_areaname, cla_areaini, cla_area, rla_lonmask_arc,\
                rla_latmask_arc, rla_lonmask_ant,  rla_latmask_ant, CMEMS_area, area_name = read_mask_polar(db)
        else:
            rla_mask, rla_maskvalues, cla_areaname, cla_areaini, cla_area, \
                    rla_lonmask, rla_latmask, CMEMS_area, area_name = read_mask(db, fmt_mask)
            if fmt_mask == 'basin':
                dirout = dirNCout
            elif fmt_mask == 'bins2d_arc':
                prefix = 'bins2d_product_quality_stats_NH_polar_'+fmt_mask
                dirout = dirBOXout
            elif fmt_mask == 'bins2d_ant':
                prefix = 'bins2d_product_quality_stats_SH_polar_'+fmt_mask
                dirout = dirBOXout
            else:
                dirout = dirBOXout
    except:
        print("Error input grid not find:", sys.exc_info()[0])
        raise

    return rla_mask, rla_maskvalues, rla_mask_arc, rla_mask_ant, dirout, prefix,  cla_area, cla_areaname, cla_areaini, rla_lonmask,\
            rla_latmask, rla_lonmask_arc, rla_latmask_arc, rla_lonmask_ant, rla_latmask_ant, CMEMS_area, area_name

# -----------------------------------------------------------------------------------------------------------------

def mask(fmt_mask, basin_mask, box_mask, bins025d_mask, bins05d_mask, bins1d_mask,\
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


# -----------------------------------------------------------------------------------------------------------------

def cfg_ltime(cl_file, cexp, cvar):

    lead_time = [] 
    yout = 0
    missing_value = 1e35
    nb_fcst = None

    nc   = netCDF4.Dataset(cl_file,'r')
    if 'observation' in nc.variables or cvar.upper() in nc.variables: lead_time.append('observation')
    if 'best_estimate' in nc.variables: lead_time.append('best_estimate')
    if 'forecast' in nc.variables: 
        lead_time.append('forecast')
        if 'numfcsts' in nc.dimensions:
            nb_fcst = nc.dimensions['numfcsts'].size
        else:
            nb_fcst = 1   
    if 'persistence' in nc.variables: 
        lead_time.append('persistence')
    if 'climatology' in nc.variables: lead_time.append('climatology')
    nc.close()  
    if 'best_estimate' in lead_time : yout += 1
    if 'forecast' in lead_time :
        if nb_fcst == 1 : yout += 1
        else:
            for f in range(nb_fcst//2): yout += 1
    if 'persistence' in lead_time :
        if nb_fcst == 1 : yout += 1
        elif nb_fcst > 1 :
            for f in range(nb_fcst//2): yout += 1
    if 'climatology' in lead_time : yout += 1
    if 'climatology' not in lead_time : yout += 1
    rla_forecast =  np.zeros((yout))
    num_col = 0
    if 'best_estimate' in lead_time :
        rla_forecast[num_col] = 0.
        num_col += 1
    if 'forecast' in lead_time and cexp == 'BIO':
        rla_forecast[num_col] = 336.
        num_col += 1
    if 'forecast' in lead_time and cexp == 'PHYS' and nb_fcst != None:
        for f in range(nb_fcst//2):
            rla_forecast[num_col] = (f*48.)+12.
            num_col += 1
    if 'persistence' in lead_time and cexp == 'BIO':
        rla_forecast[num_col] = missing_value
        num_col += 1
    if 'persistence' in lead_time and cexp == 'PHYS' and nb_fcst != None:
        for f in range(nb_fcst//2):
            rla_forecast[num_col] = missing_value
            num_col += 1
    if 'climatology' in lead_time :
        rla_forecast[num_col] = missing_value

    return lead_time, nb_fcst, yout, rla_forecast


# -----------------------------------------------------------------------------------------------------------------

def stat_mod_obs(stat,num_col,amask,nobs, mean_obs, rms_obs, mean_prod, rms_prod, rmse, cor, tab_prof, yout):

    if num_col == 0 :
        for ncol in range(yout):
            stat[ncol,:,1,amask] = mean_obs
            stat[ncol,:,2,amask] = np.square(rms_obs)

    stat[num_col,:,0,amask] = nobs
    stat[num_col,:,3,amask] = mean_prod
    stat[num_col,:,4,amask] = np.square(rms_prod)
    stat[num_col,:,5,amask] = np.square(rmse)
    stat[num_col,:,6,amask] = cor

    num_col += 1
    return stat, num_col


# -----------------------------------------------------------------------------------------------------------------

def stat_obs_glob(stat, yout, ilayer, mean, rms):
    for ncol in range(yout):
        stat[ncol,ilayer,1] = mean
        stat[ncol,ilayer,2] = np.square(rms)
    #if ~ np.isnan(np.array(mean)):
    #    print "Inside mod obs"
    #    print ncol,ilayer
    #    print stat[0,0,:]
    #    print '-----------------'
    return stat


# -----------------------------------------------------------------------------------------------------------------

def stat_mod_glob(stat, num_col, ilayer, nobs, mean, rms, rmse, cor):
    stat[num_col,ilayer,0] = nobs
    stat[num_col,ilayer,3] = mean
    stat[num_col,ilayer,4] = np.square(rms)
    stat[num_col,ilayer,5] = np.square(rmse)
    stat[num_col,ilayer,6] = cor
    num_col += 1

    return stat, num_col


# -----------------------------------------------------------------------------------------------------------------

def stat_mod_glob2(stat, num_col, ilayer, nobs, mean, rms, rmse, cor, meandiff, rmsdiff):
    stat[num_col,ilayer,0] = nobs
    stat[num_col,ilayer,3] = mean
    stat[num_col,ilayer,4] = np.square(rms)
    stat[num_col,ilayer,5] = np.square(rmse)
    stat[num_col,ilayer,6] = cor
    stat[num_col,ilayer,7] = meandiff
    stat[num_col,ilayer,8] = rmsdiff
    #if ~ np.isnan(np.array(mean)):
    #    print "Inside mod glob"
    #    print stat[0,0,:]
    #    print num_col,ilayer
    #    print nobs, mean, np.square(rms), np.square(rmse), cor, meandiff , rmsdiff
    #    print meandiff/nobs
    #    print "*****"
    #    print stat[0,0,7] /stat[0,0,0]
    #    print stat[0,0,1]-stat[0,0,3]
    #    print "----------------"
    #    sys.exit(1)
    num_col += 1

    return stat, num_col


# -----------------------------------------------------------------------------------------------------------------

def read_NC_tmp(statfile):

    nc = netCDF4.Dataset(statfile,'r')
    stat = nc.variables['stat_var'][:]
    fcst = nc.variables['forecast'][:]
    lead_time = nc.variables['lead_time'][:]
    leadtime = define_config.pull_names(lead_time)
    if 'area_names' in nc.variables : 
        area_names = nc.variables['area_names'][:]
    else :
        area_names = None
    nc.close()

    return stat, fcst, area_names, leadtime


