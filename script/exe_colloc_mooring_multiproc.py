import matplotlib
import os, sys, getopt
sys.path.append('../../modules/')
import resource
from mpi4py import MPI
import dill
from Logger import Logger
import numpy as np
import xarray as xr
from glob import glob
import pandas as pd
from scipy.spatial import cKDTree
from collections import Counter

#from pykdtree.kdtree import KDTree
import netCDF4
import datetime as dt
from dateutil.relativedelta import relativedelta
from interpolate import search_orca, lon_lat_to_cartesian
from utils import compute_last_day_month
from reader import read_moor, read_pos, read_depth
from writer import write_data_colloc_files_daily, write_data_colloc_files 
import dask
import arithm
from loader_post import load_db
import psutil
from geomlib import CheckDistance
#os.environ["OMP_NUM_THREADS"] = "3"
from Interp_kdtree import interp_KDtree

dask.config.set(scheduler="synchronous")

# *************************************************************************************
#
#   Ce programme permet de generer les CLASS2 (modele sur les points de mouillage)
#                            sous format netCDF 
#
# *************************************************************************************


# ~~~~~~~~~~~~~~~ Define creation of netCDF file or timeseries plot ~~~~~~~~~~~~~~~~~~~

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#               MAIN COLLOCATION CODE: Spatial and temporal collocations
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ********************** Set Stack unlimited **********************************

resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                       INPUT PARAMETERS SETTINGS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

letters = 'y:m:t'
keywords = ['year=', 'month=', 'tstp=', 'system=']
cla_opts = getopt.getopt(sys.argv[1:],letters,keywords)

for o,p in cla_opts[0]:
    if o in ['-y','--year']:
        YEAR = int(p)
    elif o in ['-m','--month']:
        MONTH = int(p)
    elif o in ['-t','--tstp']:
        tstp = str(p)
    elif o in ['-s','--system']:
        SYSTEM = str(p)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Define the time period ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if MONTH < 10: MONTH2 = '0'+str(MONTH)
else: MONTH2 = str(MONTH)
DAY = compute_last_day_month(YEAR,MONTH)
dt_start = dt.date(YEAR,MONTH,1)
dt_end = dt.date(YEAR,MONTH,DAY)

ndays = (dt_end - dt_start).days + 1
ts = np.array([dt_start + dt.timedelta(i) for i in range(ndays)])

# ~~~~~~~~~~~~~~~~~~~~~~~~ Define configuration (path, date, etc.) ~~~~~~~~~~~~~~~~~~~~

level = 2
log = Logger('TEP_CLASS2').run(level)
db_file = '../cfg/config_'+SYSTEM+'_CL2.cfg'

params_conf = load_db(db_file)
coordinates = params_conf.get('static','coordinates')
DIRDATA = params_conf.get('input_dir','DIRDATA')
path_fcst = params_conf.get('input_dir','dirdata_mod')
dirdata_mod = params_conf.get('input_dir','dirdata_mod_weekly')
path_data = params_conf.get('output_dir','path_data')
typemoor = params_conf.get('GLOBAL','typemoor')
zone = params_conf.get('GLOBAL','ZONE')
DIR_INTERP = params_conf.get('output_dir','DIR_INTERP')
nb_ptsinterp = params_conf.get('GLOBAL','nb_ptsinterp') 
save=False

tab_daily_moor={}
tab_daily_moor['TEMP']='votemper'
tab_daily_moor['PSAL']='vosaline'
tab_daily_moor['ZCUR']='vozocrtx'
tab_daily_moor['MCUR']='vomecrty'

tab_hourly_moor={}
tab_hourly_moor['TEMP']='sotemper'
tab_hourly_moor['PSAL']='sosaline'
tab_hourly_moor['ZCUR']='sozocrtx'
tab_hourly_moor['MCUR']='somecrty'

log.info ('Launch mooring process')

if tstp == 'hourly':
    variable = tab_hourly_moor[typemoor]
elif tstp == 'daily':
    variable = tab_daily_moor[typemoor]

system = SYSTEM
 
missing_value = 1e35
dateCNESref   = dt.datetime.strptime('1950010100','%Y%m%d%H').toordinal()
if int(YEAR) < 2019 or (int(YEAR) == 2019 and int(MONTH) < 7) or tstp == 'daily':
    forecast = []
    fcst_hour = []
else: 
    forecast = [1,3,9] # echeance de forecast considere
    fcst_hour = [12,60,204] # echeance de forecast considere



# ~~~~~~~~~~~~~~~~~~~ Read model grid point coordinates (lat/lon) ~~~~~~~~~~~~~~~~~~~~~
## Init pickle
MPI.pickle.__init__(dill.dumps, dill.loads)

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
log.info ('Read model coordinates')
mod_coord = xr.open_dataset(coordinates)

if rank == 0:
    lon_mod, lat_mod = read_pos(coordinates, log)

    # ******************************** SPATIAL COLLOCATION *********************************

    ind_dict ={}

    # ~~~~~~~~ Read mooring coordinates and compute 2D collocation with the model grid ~~~~~~~~~

    frame = DIRDATA+str(YEAR)+str(MONTH2)+'/'+zone+'_*'+str(YEAR)+str(MONTH2)+'*.nc'  
    nb_files = 0
    for f, file in enumerate(glob(frame)):
        lon_value, lat_value, depth, depth_qc, time, temp, ll_temp, temp_qc = read_moor(file, log)
        if ll_temp: nb_files +=1
    list_lat_lon = np.nan*np.zeros((nb_files,2))
    list_mooring = []
    list_lon = []
    list_lat = []
    log.info ("Nb file total : %s" %(str(nb_files)))
    ind_moor = 0
    for f, file in enumerate(glob(frame)):
        moor =  os.path.basename(file).split('_')[3:][0]
        log.debug (moor)
        lon_value, lat_value, depth, depth_qc, time, temp, ll_temp, temp_qc = read_moor(file, log)
        if typemoor == "TEMP":
           if ll_temp:
              ind_dict[moor] = {}           
              list_mooring.append(moor)
              list_lat_lon[ind_moor,0] = lat_value
              list_lat_lon[ind_moor,1] = lon_value
              list_lat.append(lat_value)
              list_lon.append(lon_value)
              ind_dict[moor]['lat'] = lat_value
              ind_dict[moor]['lon'] = lon_value   
              ind_moor += 1
    nb_files = len(list_mooring)
    log.info ("Nb files %s : %s" %(typemoor, str(nb_files)))
    if nb_files < 1: 
        log.error ("Missing moorings")
        sys.exit(1)
    collec = Counter(list_mooring)
    log.debug (collec.most_common(10))

    weight_file = DIR_INTERP+'weight_file_'+str(nb_ptsinterp)+'pts_'+str(nb_files)+'moorings_'+str(typemoor)+"_"+str(YEAR)+"_"+str(MONTH2)+".nc"
    log.info ("Interp Kdtree")
    TreeObj = interp_KDtree(log)
    dist, idw = TreeObj.tree_and_query(lon_mod, lat_mod,\
                                       np.array(list_lon), np.array(list_lat),\
                                       int(nb_ptsinterp), weight_file=weight_file, save=save)

    ilat, ilon = TreeObj.get_ilonlat(lon_mod, lat_mod, idw)
    log.info ("Coloc 2D ok %s" %(str(nb_files)))

    for i in range(len(ilat)):
        ind_dict[list_mooring[i]]['ind_lat'] = ilat[i]
        ind_dict[list_mooring[i]]['ind_lon'] = ilon[i]


    # ******************************** CREATE NETCDF FILE *********************************
 
    # ~~~~~~~~~~~~~~~~~~~ Select model files for the considered month ~~~~~~~~~~~~~~~~~~~~~~~~~~

    liste_file = []
    for t in ts:
        if tstp == 'hourly':
            path = dirdata_mod+'/'
            framefile = system+'_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc'
            log.info ("Input hourly files directory: %s ; %s " %(path, framefile))
            file_mod  = sorted(glob(dirdata_mod+'/'+system+'_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc'))
        elif tstp == 'daily':
            file_mod  = glob(dirdata_mod+'/'+system+'_1dAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')              
        if len(file_mod) == 0:
            log.info("File missing")
            if tstp == 'hourly':
                file_mod  = sorted(glob(dirdata_mod+str(YEAR+1)+'/*/'+system+'_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc'))
            if tstp == 'daily':
                file_mod  = glob(dirdata_mod+str(YEAR+1)+'/*/'+system+'_1dAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')     
        if len(file_mod) > 0 and file_mod[0] not in liste_file:
            liste_file.append(file_mod[0])

    log.info ("List input file ok")
    log.info(liste_file)
    if len(forecast) > 0:
        liste_fcst = {}
        for fc in forecast:
            lfc = []
            for t in ts:
                if tstp == 'hourly':
                    file_fcst = sorted(glob(path_fcst+'fcst'+str(fc)+'/*_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc'))
                if len(file_fcst) > 0 and file_fcst[0] not in lfc:
                    lfc.append(file_fcst[0])
            liste_fcst[str(fc)] = lfc
	##
        if len(file_fcst) == 0:
            log.error("Missing files for forecast")
            sys.exit(1)
    depth_mod = read_depth(liste_file[0])
    log.info("Create mfdadaset HDCT")
    try:
        mfdataset_hdct = xr.open_mfdataset(liste_file, concat_dim='time_counter', autoclose=True)
        time_mod = mfdataset_hdct.variables['time_counter'][:].values
    except Exception as exs:
        log.error("Execution mfdataset_hdct failed: %s", exs)
        raise

    log.info("Create mfdadaset HDCT OK")

    if len(forecast) > 0:
        mfdataset_fcst = {}
        time_fcst = {}
        for fc in forecast:
            log.info("Create mfdadaset FCST {}".format(fc))
            log.info("Nb files {} ".format(len(liste_fcst[str(fc)])))
            try :
                mfdataset_fcst[str(fc)] = xr.open_mfdataset(liste_fcst[str(fc)], concat_dim='time_counter', autoclose=True)
                time_fcst[str(fc)] = mfdataset_fcst[str(fc)].variables['time_counter'][:].values
            except Exception as exs:
               log.error ("Execution mfdataset_fcst failed: %s", exs)
               raise
            log.info("Create mfdadaset FCST OK {}".format(fc))
            meminfo = psutil.Process().memory_info().rss / 2**20
            log.debug("RSS memory information : %s " %(str(meminfo)))

    log.info ("Create dataset ok ")
    # ~~~~~~~~ Read mooring coordinates and compute 2D collocation with the model grid ~~~~~~~~~

    list_file = []
    for file in glob(frame):
        list_file.append(file)

else:
    ind_dict, depth_mod, mfdataset_hdct, time_mod, list_file = None, None, None, None, None
    if len(forecast) > 0:
        mfdataset_fcst, time_fcst = None, None

log.debug ("Create broadcast ") 
ind_dict = comm.bcast(ind_dict, root=0)
depth_mod = comm.bcast(depth_mod, root=0)
mfdataset_hdct = comm.bcast(mfdataset_hdct, root=0)
time_mod = comm.bcast(time_mod, root=0)
list_file = comm.bcast(list_file, root=0)
if len(forecast) >0:
    mfdataset_fcst = comm.bcast(mfdataset_fcst, root=0)
    time_fcst = comm.bcast(time_fcst, root=0)


# *********** repartition dates sur processeurs ***********

nmoor = len(list_file)
irest  = np.mod(nmoor,comm.size)
ntask  = nmoor // comm.size
istart = ntask*comm.rank
iend   = istart + ntask - 1
cla_mr = list_file[istart:iend+1]
iend_tot = ntask*comm.size-1
if irest > 0 and comm.rank < irest:
    cla_mr.append(list_file[iend_tot+comm.rank+1])

for file in cla_mr:

    moor =  os.path.basename(file).split('_')[3:][0]

    if tstp == 'hourly':
        nc_file_out = path_data+moor+'_MOD_TS_GLOMFC-PU_'+str(YEAR)+MONTH2+'_TEMP.nc'
    elif tstp == 'daily':
        nc_file_out = path_data+moor+'_MOD_TS_GLOMFC-PU_'+str(YEAR)+MONTH2+'_TEMP_DAILY.nc'

    lon_value, lat_value, depth, depth_qc, time, temp, ll_temp, t_qc = read_moor(file, log)

    var_moor = [] ; temp_qc = [] ; depth_moor = []
    if np.size(temp) == 1 and np.isnan(temp): continue
    if len(np.shape(np.array(temp))) > 1: 
        w = np.where(np.array(depth.data) >= 0)[0]
        if len(w) > 0:
            cont_act = False
            for ini in range(len(w)):
                if np.isnan(np.nanmean(np.array(temp)[:,w[ini]])) or depth[w[ini]] > 1 or cont_act: continue
                else : cont_act = True
                var_moor = np.array(temp)[:,w[ini]]
                depth_moor = depth.data[w[ini]]
                temp_qc = np.array(t_qc)[:,w[ini]]
                        
    if len(var_moor) == 0: continue
    w = np.where(temp_qc != 1.)
    var_moor[w[0]] = np.nan

    temp = var_moor

    if np.isnan(np.nanmean(temp)) == True: continue

    log.info ('Mooring: '+moor)

    # ****************************************************************************

    ilon = ind_dict[moor]['ind_lon']
    ilat = ind_dict[moor]['ind_lat']
    #dist = CheckDistance(mod_coord.nav_lon.isel(x=xr.DataArray(ilon, dims=['point']),
    #   y=xr.DataArray(ilat, dims=['point'])).values,
    #   mod_coord.nav_lat.isel(x=xr.DataArray(ilon, dims=['point']),
    #   y=xr.DataArray(ilat, dims=['point'])).values,
    #   lon_value, lat_value, dist_max=10., name="MODEL_"+moor)

    w = np.where(abs(depth_mod-depth_moor) == np.nanmin(abs(depth_mod-depth_moor)))
    ind_depth = depth_mod[w[0][0]]

    if tstp == 'daily':
        ds = mfdataset_hdct.sel(x=ilon, y=ilat, deptht=ind_depth)
        time = ds.variables['time_counter'][:].values
        values_temp = ds.variables[variable][:].values

    vtime = time.astype('M8[ms]').astype('O')
    stt_date = vtime[0].strftime('%Y%m%d')
    end_date = vtime[-1].strftime('%Y%m%d')
    vect_time = []
    for t in range(len(vtime)):
        if tstp == 'hourly':
            vect_time.append(vtime[t].strftime('%Y%m%d%H'))    
        elif tstp == 'daily' and vtime[t].strftime('%Y%m%d') not in vect_time:
            vect_time.append(vtime[t].strftime('%Y%m%d'))  

    if tstp == 'hourly':
        ind_time = []
        for timevalue in time:
            index_time = np.argmin(np.abs(time_mod-timevalue))
            ind_time.append(time_mod[index_time])

        if len(forecast) > 0:
            ind_time_fcst = {}
            vt_fcst = {}
            for fc in forecast:
                ind_time_fcst_tmp = []
                vt_fcst_tmp = []                
                for timevalue in time:
                    index_time_fcst = np.argmin(np.abs(time_fcst[str(fc)]-timevalue))
                    ind_time_fcst_tmp.append(time_fcst[str(fc)][index_time_fcst])
                ind_time_fcst[str(fc)] = ind_time_fcst_tmp 
                for t in range(len(time_fcst[str(fc)])):
                    vt_fcst_tmp.append(pd.to_datetime(str(time_fcst[str(fc)][t])).strftime('%Y%m%d%H')) 
                vt_fcst[str(fc)] = vt_fcst_tmp          

    ndays = len(vect_time)
    vector_time = np.zeros((ndays))
    for il_ind, day in enumerate(np.array(vect_time)):
        if tstp == 'hourly':
            vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d%H').toordinal()-dateCNESref)*24+int(day[8:10])
        elif tstp == 'daily':
            vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref)*24

    if tstp == 'hourly':
        values_temp = np.nan*np.zeros((len(vector_time), len(forecast)+1))
        ds = mfdataset_hdct.sel(x=ilon, y=ilat, time_counter=np.array(ind_time), deptht=ind_depth)
        values_temp[:,0] = ds.variables[variable][:].values
        if len(forecast) > 0:
            for fc,fcst in enumerate(forecast):
		#
                try: 
                    meminfo = psutil.Process().memory_info().rss / 2**20
                    log.debug("RSS memory information : {} ".format(str(meminfo)))
                    mfd_fcst = mfdataset_fcst[str(fcst)]
                    ds_fcst = mfd_fcst.sel(x=ilon, y=ilat, time_counter=np.array(ind_time_fcst[str(fcst)]), deptht=ind_depth)               
                    values_temp[:,fc+1] = ds_fcst.variables[variable][:].values
                    meminfo = psutil.Process().memory_info().rss / 2**20
                except Exception as exs:
                    log.error("Pb during mfdataset construction fcst :%s " %(exs))
                    log.error("Create mfdadaset FCST NOK {}".format(fc))
                    raise
                for tc, timec in enumerate(vect_time): 
                    w = np.where(np.array(vt_fcst[str(fcst)]) == timec)           
                    if len(w[0]) == 0:
                        values_temp[tc,fc+1] = np.nan
                     

    # ~~~~~~~~~~~~~ Save the Class2 (model/mooring) in a netcdf file ~~~~~~~~~~~~~~~~~~
        
    if (tstp == 'hourly' and np.isnan(np.nanmean(values_temp[:,0])) == True) or (tstp == 'daily' and np.isnan(np.nanmean(values_temp)) == True): continue

    w_nan = np.where(np.isnan(values_temp)==True)
    if len(w_nan) > 0:
        values_temp[w_nan] = missing_value

    if tstp == 'hourly':
        if len(forecast) > 0:
            write_data_colloc_files(nc_file_out, lat_value, lon_value, values_temp, vector_time, stt_date, end_date, depth_moor, missing_value, ech_fcst = np.insert(np.array(fcst_hour),0,0))  
        else: write_data_colloc_files(nc_file_out, lat_value, lon_value, values_temp, vector_time, stt_date, end_date, depth_moor, missing_value)
        del nc_file_out, lat_value, lon_value, temp, values_temp, vector_time
    elif tstp == 'daily':
        write_data_colloc_files_daily(nc_file_out, lat_value, lon_value, values_temp, vector_time, stt_date, end_date, depth_moor, ind_depth, missing_value)  
        del nc_file_out, lat_value, lon_value, values_temp, vector_time, depth_moor, ind_depth
                
comm.Barrier()
log.info ("End of Program")
