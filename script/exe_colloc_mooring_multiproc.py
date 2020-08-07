import matplotlib
import os, sys, getopt
from os.path import dirname
sys.path.append('/home/ext/mr/smer/regnierc/SAVE/python/module/')
#sys.path.append(dirname(__file__)+'/../modules/')
sys.path.append('/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/python/module/')
sys.path.append('/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/python/module/supobs/')
import resource
from mpi4py import MPI
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
from interpolate import coloc_2D, search_orca, lon_lat_to_cartesian
from utils import compute_last_day_month
from reader import read_moor, read_pos, read_depth
from writer import write_data_colloc_files_daily, write_data_colloc_files 
import dask
import arithm
from loader import load_db
import psutil
from geomlib import CheckDistance
#os.environ["OMP_NUM_THREADS"] = "3"

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
#                                  FUNCTIONS
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


def coloc_2D(lon_in, lon_out, lat_in, lat_out,
             nbpts_interp, log):
    """
    -------------------
    Coloc 2D
    Compute weight file with KDTree Method and store it in
    a pickle file
    Arguments
    --------------------
    lon_in : input longitude array
    lon_out : output longitude array
    lat_in : input latitude array
    lat_out : output latitude array
    nbpts_interp : number points for interpolation
        =>  1 = nearest
        =>  >1 IDW method
    log : logger object
    Returns
    --------------------
    WEIGHT : weight values
    inds_idw1 : index values in the grid
    """  

    # Read input grid
    # Test size
    if len(lon_in.shape) > 1:
        X1, Y1 = lon_in, lat_in
    else:
        X1, Y1 = np.meshgrid(lon_in, lat_in)
    # Convert to cartesian
    xs, ys, zs = lon_lat_to_cartesian(X1.flatten(), Y1.flatten())
    # Read output grid
    X2, Y2 = lon_out, lat_out
    if isinstance(X2, np.float64) or isinstance(X2, np.float32):
        log.info('X2 is a float')
    else:
        global_step = (X2[len(X2)-1]-X2[0])/(len(X2)-1)
        first_step = X2[1]-X2[0]
        log.info('Step sizes %f %f ' % (global_step, first_step))
    # 1D cases
    if  lon_out.ndim  == 0:
        log.info('1D not regular')
        X2, Y2 = lon_out, lat_out
    elif lon_out.ndim < 2:
        if global_step == first_step:
            # Regular
            log.info('1D regular => convert to meshgrid')
            X2, Y2 = np.meshgrid(lon_out, lat_out)
        else:
            # Irregular
            log.info('1D not regular')
            X2, Y2 = lon_out, lat_out
    # Convert to cartesian
    xt, yt, zt = lon_lat_to_cartesian(X2.flatten(), Y2.flatten())
    if sys.version_info[0] >= 3:
        tree = cKDTree(list(zip(xs, ys, zs)))
        DIST, inds_idw1 = tree.query(
            list(zip(xt, yt, zt)), k=nbpts_interp)
    else:
        tree = cKDTree(zip(xs, ys, zs))
        DIST, inds_idw1 = tree.query(zip(xt, yt, zt), k=nbpts_interp)

    ilat = []
    ilon = []
    for ind in inds_idw1:
        inds = np.where(lon_in == lon_in.flatten()[ind]) 
        if np.size(inds[0][:]) > 1:
            w = np.where(lat_in[inds] == lat_in.flatten()[ind])
            ilat.append(inds[0][w][0])
            ilon.append(inds[1][w][0])
        else: 
            ilat.append(inds[0][0])
            ilon.append(inds[1][0])

    return ilat, ilon, DIST

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
##ts = np.array([dt_start + dt.timedelta(i) for i in xrange(ndays)])
## Modif
ts = np.array([dt_start + dt.timedelta(i) for i in range(ndays)])


# ~~~~~~~~~~~~~~~~~~~~~~~~ Define configuration (path, date, etc.) ~~~~~~~~~~~~~~~~~~~~

level = 1
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

print (variable)
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
    print (glob(frame))
    # moor =  os.path.basename(file).split('_')[4].split('.')[0]
    ind_moor = 0
    for f, file in enumerate(glob(frame)):
        moor =  os.path.basename(file).split('_')[3:][0]
	#print (moor)
	#moor = [''.join(var[0:])][0].split('.nc')[0]
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
    collec = Counter(list_mooring)
    #print (collec.most_common(10))

    weight_file = DIR_INTERP+'weight_file_'+str(nb_ptsinterp)+'pts_'+str(nb_files)+'moorings_'+str(typemoor)+"_"+str(YEAR)+"_"+str(MONTH2)+".nc"
    log.info ("Interp Kdtree")
    TreeObj = interp_KDtree()
    dist, idw = TreeObj.tree_and_query(lon_mod, lat_mod,\
                                       np.array(list_lon), np.array(list_lat),\
                                       int(nb_ptsinterp), weight_file=weight_file, save=save)

    ilat, ilon = TreeObj.get_ilonlat(lon_mod, lat_mod, idw)
    #ilat, ilon, dist = coloc_2D(lon_mod, list_lat_lon[:,1], lat_mod, list_lat_lon[:,0],
    #                            int(nb_ptsinterp), log)
    
#idw, dist = coloc_2D(lon_mod, list_lat_lon[:,1], lat_mod, list_lat_lon[:,0],
    #                     weight_file, int(nb_ptsinterp), log)
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
            file_mod  = glob(dirdata_mod+'/'+system+'_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')
        elif tstp == 'daily':
            file_mod  = glob(dirdata_mod+'/'+system+'_1dAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')              
        if len(file_mod) == 0:
            log.info("File missing")
            if tstp == 'hourly':
                file_mod  = glob(dirdata_mod+str(YEAR+1)+'/*/'+system+'_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')
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
                    file_fcst = glob(path_fcst+'fcst'+str(fc)+'/*_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')
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
        print ("Execution mfdataset_hdct failed: %s", exs)
        sys.exit(1)

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
               print ("Execution mfdataset_fcst failed: %s", exs)
               sys.exit(1)
            meminfo = psutil.Process().memory_info().rss / 2**20
            print("RSS memory information : %s " %(str(meminfo)))
     
    log.info ("Create dataset ok ")
    # ~~~~~~~~ Read mooring coordinates and compute 2D collocation with the model grid ~~~~~~~~~
    
    list_file = []
    for file in glob(frame):
        list_file.append(file)

else:
    ind_dict, depth_mod, mfdataset_hdct, time_mod, list_file = None, None, None, None, None
    if len(forecast) > 0:
        mfdataset_fcst, time_fcst = None, None

     
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
   # moor =  os.path.basename(file).split('_')[3].split('.')[0]
    moor =  os.path.basename(file).split('_')[3:][0]
    #var =  os.path.basename(file).split('_')[3:]
    #moor = var[0]

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
                    print("RSS memory information : {} ".format(str(meminfo)))
                    mfd_fcst = mfdataset_fcst[str(fcst)]
                    #print ("Indices")
                    #print (ilon,ilat)
                    #print (np.array(ind_time_fcst[str(fcst)]))
                    #print (ind_depth)
                    #print ("----------")
                    ds_fcst = mfd_fcst.sel(x=ilon, y=ilat, time_counter=np.array(ind_time_fcst[str(fcst)]), deptht=ind_depth)               
                    values_temp[:,fc+1] = ds_fcst.variables[variable][:].values
                    meminfo = psutil.Process().memory_info().rss / 2**20
                    print("RSS memory information : %s " %(str(meminfo)))
                except Exception as exs:
                    print ("Pb during mfdataset construction fcst :%s " %(exs))
                    log.info("Create mfdadaset FCST NOK {}".format(fc))
                    sys.exit(1)
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
