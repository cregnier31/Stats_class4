import os, sys
sys.path.append('../../modules/')
import resource, re
from mpi4py import MPI
import dill
from Logger import Logger
import numpy as np
import xarray as xr
from glob import glob
import pandas as pd
import datetime as dt
from utilities import findListFiles as find_lf
from utilities import readDataSet as read_dtset
from utils import compute_last_day_month
from reader import read_moor, read_pos, read_depth
from writer import write_data_colloc_files_daily, write_data_colloc_files, write_data_json_file
import dask
import psutil
from Interp_kdtree import interp_KDtree
import configparser as ConfigParser
from ast import literal_eval
import time as tt

#dask.config.set(scheduler="synchronous")
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# *************************************************************************************
#   Ce programme permet de generer les CLASS2 (modele sur les points de mouillage)
#                            sous format netCDF
# *************************************************************************************

# ~~~~~~~~~~~~~~~~~~~~ Add input paramaters (system, date, timestep) ~~~~~~~~~~~~~~~~~~

if len(sys.argv) < 2:
    print ('example: python exe_colloc_mooring_multiproc_new.py system date timestep old_obs')
    sys.exit(1)
elif len(sys.argv) == 5:
    system = sys.argv[1]
    YEAR = sys.argv[2][0:4]
    MONTH = sys.argv[2][4:6]
    tstp = sys.argv[3]
    old_obs = sys.argv[4]
elif len(sys.argv) == 4:
    system = sys.argv[1]
    YEAR = sys.argv[2][0:4]
    MONTH = sys.argv[2][4:6]
    tstp = sys.argv[3]
    old_obs = 'new'
elif len(sys.argv) == 3:
    system = sys.argv[1]
    YEAR = sys.argv[2][0:4]
    MONTH = sys.argv[2][4:6]
    tstp = 'hourly'
    old_obs = 'new'
else:
    system = sys.argv[1]
    YEAR = dt.datetime.now().strftime('%Y')
    MONTH = dt.datetime.now().strftime('%m')
    tstp = 'hourly'
    old_obs = 'new'

# ~~~~~~~~~~~~~~~~~~~~ Define configuration (path, mask, interp) ~~~~~~~~~~~~~~~~~~~~

level = 6
log = Logger('TEP_CLASS2').run(level)

IniRead = ConfigParser.ConfigParser()
config_file = '../cfg/config_'+system+'_CL2.cfg'
IniRead.read(os.path.expanduser(config_file))
coordinates = IniRead.get('static','coordinates')
dir_obs = IniRead.get('input_dir','dir_obs')
dir_mod = IniRead.get('input_dir','dir_mod')
dir_mod_hebdo = IniRead.get('input_dir','dir_mod_hebdo')
path_out = IniRead.get('output_dir','path_out')
typemoor = IniRead.get('params','typemoor')
zone = IniRead.get('params','zone')
dir_interp = IniRead.get('output_dir','dir_interp')
nb_ptsinterp = IniRead.getint('params','nb_ptsinterp')
missing_value = 1e35
varname = literal_eval(IniRead['params']['varname'])
forecast = literal_eval(IniRead['params']['forecast'])
if tstp == 'hourly' and varname[typemoor] in ['temper', 'saline']: variable = 'so' + varname[typemoor]
elif tstp == 'daily' and varname[typemoor] in ['temper', 'saline']: variable = 'vo' + varname[typemoor]
else: variable = varname[typemoor]
dateCNESref   = dt.datetime.strptime('1950010100','%Y%m%d%H').toordinal()
system_filen = IniRead.get('nomenclature_file','system')
systemQ_filen = IniRead.get('nomenclature_file','systemQ')
grid_filen = IniRead.get('nomenclature_file','grid')
mean_filen = IniRead.get('nomenclature_file','mean')
grid_var_filen = IniRead.get('nomenclature_file','grid_var')

if old_obs == 'new':
    DAY = compute_last_day_month(int(YEAR),int(MONTH))
    dt_start = dt.date(int(YEAR),int(MONTH),1)
    dt_end = dt.date(int(YEAR),int(MONTH),DAY)
else:
    list_date = []
    lfile = sorted(glob(dir_mod_hebdo+system_filen+grid_filen+'_1'+\
                        tstp[0]+mean_filen+'*'+grid_var_filen+'*.nc'))
    for f in lfile:
        list_date.append(f.split(dir_mod_hebdo+system_filen+grid_filen+'_1'+\
                                 tstp[0]+mean_filen+'_')[1].split('-')[0])
    dt_start = dt.date(int(list_date[0][0:4]),int(list_date[0][4:6]), int(list_date[0][6:8]))
    dt_end = dt.date(int(list_date[-1][0:4]),int(list_date[-1][4:6]), int(list_date[-1][6:8]))
    dts_mod = int(list_date[0][0:4]+list_date[0][4:6])
    dte_mod = int(list_date[-1][0:4]+list_date[-1][4:6])

ndays = (dt_end - dt_start).days + 1
ts = np.array([dt_start + dt.timedelta(i) for i in range(ndays)])


# ~~~~~~~~~~~~~~~~~~~ Read model grid point coordinates (lat/lon) ~~~~~~~~~~~~~~~~~~~~~
# -->  Init pickle
MPI.pickle.__init__(dill.dumps, dill.loads)
comm = MPI.COMM_WORLD
rank = comm.Get_rank()

mod_coord = xr.open_dataset(coordinates)
start_time_ini = tt.time()
if rank == 0:
    lon_mod, lat_mod = read_pos(coordinates, log)

    # ******************************** Spatial collocation *********************************
    ind_dict ={}

    # ~~~~~~~~ Read mooring coordinates and compute 2D collocation with the model grid ~~~~~~~~~
    if old_obs == 'old': frame =  dir_obs+zone+'_*.nc'
    else: frame = dir_obs+YEAR+MONTH+'/'+zone+'_*'+YEAR+MONTH+'.nc'
    nb_files = 0
    for f, file in enumerate(glob(frame)):
        lon_value, lat_value, depth, depth_qc, time, vardata, ll_var, vardata_qc = read_moor(file, typemoor, log)
        if old_obs == 'old':
            t_tmp = time.astype('M8[ms]').astype('O')
            dts_moor = t_tmp[0].strftime('%Y%m')
            dte_moor = t_tmp[-1].strftime('%Y%m')
            if int(dte_moor) < int(dts_mod) or int(dts_moor) > int(dte_mod): continue
        if ll_var: nb_files += 1
    list_mooring = []
    list_lon = []
    list_lat = []
    log.info ("Nb file total : %s" %(str(nb_files)))
    ind_moor = 0
    for f, file in enumerate(glob(frame)):
        if old_obs == 'new': moor =  os.path.basename(file).split('_')[3:][0]
        else: moor =  os.path.basename(file).split('_')[3:][0].split('.nc')[0]
        #if old_obs == 'new' and os.path.isfile(path_out+moor+'_MOD_TS_GLOMFC-PU_'+ \
        #str(YEAR)+MONTH+'_'+typemoor+'.nc'): continue
        log.debug (moor)
        lon_value, lat_value, depth, depth_qc, time, vardata, ll_var, vardata_qc = read_moor(file, typemoor, log)
        if old_obs == 'old':
            t_tmp = time.astype('M8[ms]').astype('O')
            dts_moor = t_tmp[0].strftime('%Y%m')
            dte_moor = t_tmp[-1].strftime('%Y%m')
            if len(glob(path_out+moor+'_MOD_TS_GLOMFC-PU_*DAILY.nc')) > 0: continue
            if int(dte_moor) < int(dts_mod) or int(dts_moor) > int(dte_mod): continue
        if ll_var:
            ind_dict[moor] = {}
            list_mooring.append(moor)
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

    weight_file = dir_interp+'weight_file_'+str(nb_ptsinterp)+'pts_'+\
                  str(nb_files)+'moorings_'+typemoor+'_'+YEAR+'_'+MONTH+'.nc'
    log.info ("Interp Kdtree")
    TreeObj = interp_KDtree(log)
    dist, idw = TreeObj.tree_and_query(lon_mod, lat_mod,\
                                       np.array(list_lon), np.array(list_lat),\
                                       nb_ptsinterp, weight_file=weight_file, save=False)
    ilat, ilon = TreeObj.get_ilonlat(lon_mod, lat_mod, idw)
    log.info ("Coloc 2D %s" %(str(nb_files)))
    for i, m in enumerate(list_mooring):
        ind_dict[m]['ind_lat'] = ilat[i]
        ind_dict[m]['ind_lon'] = ilon[i]

    # ******************************** Create netCDF file *********************************

    # ~~~~~~~~~~~~~~~~~~~ Select model files for the considered month ~~~~~~~~~~~~~~~~~~~~~~~~~~

    if old_obs == 'new':
        pfx = system_filen+grid_filen+'_1'+tstp[0]+mean_filen+'_'
        sfx = grid_var_filen
        liste_file = find_lf(dir_mod_hebdo, pfx, sfx, ts)
        depth_mod, multidim = read_depth(liste_file[0])
        mfdataset_hdct, time_mod = read_dtset(liste_file)

        if len(forecast) > 0:
            liste_fcst = {}
            for fc in forecast:
                pfx = 'fcst'+str(fc)+'/*_1'+tstp[0]+mean_filen+'_'
                sfx = grid_var_filen
                lfc = find_lf(dir_mod,pfx, sfx, ts)
                liste_fcst[str(fc)] = lfc

            if len(liste_fcst) == 0:
                log.error('Missing files for forecast')
                sys.exit(1)

            mfdataset_fcst = {}
            time_fcst = {}
            for fc in forecast:
                mfdataset_fcst[str(fc)], time_fcst[str(fc)] = \
                    read_dtset(liste_fcst[str(fc)], data_vars=[variable])

    # ~~~~~~~~ Read mooring coordinates and compute 2D collocation with the model grid ~~~~~~~~~

    list_file = []
    for file in glob(frame):
        if old_obs == 'new': moor_tmp = file.split('_')[-2]
        else: moor_tmp =  file.split('_')[-1].split('.nc')[0]
        if moor_tmp in list_mooring:
            list_file.append(file)
else:
    ind_dict, depth_mod, mfdataset_hdct, time_mod, list_file, multidim, dts, dte = \
    None, None, None, None, None, None, None, None
    if len(forecast) > 0:
        mfdataset_fcst, time_fcst = None, None

log.debug ("Create broadcast ")
ind_dict = comm.bcast(ind_dict, root=0)
list_file = comm.bcast(list_file, root=0)
if old_obs == 'new':
    depth_mod = comm.bcast(depth_mod, root=0)
    multidim = comm.bcast(multidim, root=0)
    mfdataset_hdct = comm.bcast(mfdataset_hdct, root=0)
    time_mod = comm.bcast(time_mod, root=0)
    if len(forecast) > 0:
        mfdataset_fcst = comm.bcast(mfdataset_fcst, root=0)
        time_fcst = comm.bcast(time_fcst, root=0)

# *********** repartition mooring sur processeurs ***********

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
    if old_obs == 'new': moor =  os.path.basename(file).split('_')[3:][0]
    else: moor = os.path.basename(file).split('_')[3:][0].split('.nc')[0]
    start_time = tt.time()
    if tstp == 'hourly': suffix = ''
    elif tstp == 'daily': suffix = '_DAILY'
    lon_value, lat_value, depth, depth_qc, time, vardata, ll_var, var_qc = read_moor(file, typemoor, log)
    if old_obs == 'new': nc_file_out = path_out+moor+'_MOD_TS_GLOMFC-PU_'+\
                         str(YEAR)+MONTH+'_'+typemoor+suffix+'.nc'
    else:
        t_tmp = time.astype('M8[ms]').astype('O')
        dts = np.nanmax([int(t_tmp[0].strftime('%Y%m')), int(dts_mod)])
        dte = np.nanmin([int(t_tmp[-1].strftime('%Y%m')), int(dte_mod)])
        nc_file_out = path_out+moor+'_MOD_TS_GLOMFC-PU_'+\
                      str(dts)+'_'+str(dte)+'_'+typemoor+suffix+'.nc'
        pfx = system_filen+grid_filen+'_1'+tstp[0]+mean_filen+'_'
        sfx = grid_var_filen
        liste_file = find_lf(dir_mod_hebdo, pfx, sfx, ts, dt_start=dts, dt_end=dte)
        if varname[typemoor] in ["thetao"]: depth_mod, multidim = read_depth(liste_file[0])
        else: depth_mod, multidim = [0], False
        mfdataset_hdct, time_mod = read_dtset(liste_file)
        if len(forecast) > 0:
            liste_fcst = {}
            for fc in forecast:
                pfx = 'fcst'+str(fc)+'/*_1'+tstp[0]+mean_filen+'_'
                sfx = grid_var_filen
                lfc = find_lf(dir_mod, pfx, sfx, ts)
                liste_fcst[str(fc)] = lfc
            if len(liste_fcst) == 0:
                log.error('Missing files for forecast')
                sys.exit(1)
            mfdataset_fcst = {}
            time_fcst= {}
            for fc in forecast:
                mfdataset_fcst[str(fc)], time_fcst[str(fc)] = read_dtset(liste_fcst[str(fc)])
    json_file_out = re.sub('.nc', '.json', nc_file_out)
    cont_act = False
    nb_dims_profs = len(np.shape(depth))
    if not ll_var:
        print(f'Missing variable {typemoor} for {file}')
        continue
    var_moor = []
    #vardata_qc = []
    depth_moor = []
    depthmax = 6
    # Management of different types of moorings
    if nb_dims_profs == 1:
        log.info(f'Case 1 {file}')
        nb_dims_var = len(np.shape(vardata))
        for ini, depth_val in enumerate(depth.data):
            if nb_dims_var == 1:
                value_data = np.array(vardata)[ini]
                value_data_all = np.array(vardata)
                value_qc = np.array(var_qc)[ini]
            elif nb_dims_var == 2:
                value_data = np.array(vardata)[:, ini]
                value_data_all = np.array(vardata)[:, ini]
                value_qc = np.array(var_qc)[:, ini]
            else:
                log.error(f'Case not defined {nb_dims_var}')
                sys.exit(1)
            has_valid_data = np.any(~np.isnan(value_data))
            #if depth_val < 0 or np.isnan(value_data) or depth_val > depthmax:
            if depth_val < 0 or not has_valid_data or depth_val > depthmax:
            #if depth_val < 0 or not has_valid_data:
                continue
            else :
                depth_data_all = depth.data[:]
                depth_moor.append(float(depth_val))
                var_moor.append(value_data)
                #vardata_qc.append(value_qc)
                vardata_qc = value_qc
                break
    elif nb_dims_profs == 2:
        log.info(f'Case 2 {file}')
        list_depth = depth.data[0]
        if isinstance(vardata, float) and np.isnan(vardata):
            continue
        else:
            for ini, depth_val in enumerate(list_depth):
                array_data  = np.array(vardata)[:,ini]
                if array_data.size == 0:
                    continue
                if depth_val < 0 or np.isnan(np.nanmean(array_data)) or depth_val > depthmax:
               # if depth_val < 0 or depth_val > depthmax:
                    continue
                else :
                    value_data_all = array_data
                    var_moor.append(np.nanmean(array_data))
                    depth_moor.append(float(depth_val))
                    #vardata_qc.append(np.nanmean(np.array(var_qc)[:,ini]))
                    #vardata_qc.append(np.array(var_qc)[:,ini])
                    #vardata_qc.append(np.array(vardata_qc)[:,ini])
                    vardata_qc = np.array(var_qc)[:,ini]
                    depth_data_all = np.array(depth)[:,ini]
                    #depth_all = depth.data
                    break
                #if depth_val < 0 : continue
                #elif np.isnan(np.nanmean(np.array(vardata)[:,ini])) or depth_val > depthmax or cont_act: continue
                #else : cont_act = True
                #var_moor.append(np.array(vardata)[0,ini])
                #depth_moor.append(depth_val)
                #vardata_qc.append(np.array(var_qc)[0,ini])
    elif nb_dims_profs == 0:
        log.info('Case 0')
        depth = float(depth.data)
        if depth < 0 :
            print(f"One single depth < 0 for {file}")
            continue
        depth_data_all = depth
        value_data_all = vardata.data
        value_data = vardata.data[0]
        value_qc = var_qc.data[0]
        depth_moor.append(float(depth))
        var_moor.append(value_data)
        #vardata_qc.append(value_qc)
        vardata_qc = value_qc
    elif nb_dims_profs == 3:
        log.error(f'Case prof not defined {nb_dims_prof}')
        sys.exit(1)
    log.info(f'Depth of mooring {depth_moor}')
    #if np.size(vardata) == 1 and np.isnan(vardata): continue
    #if len(np.shape(np.array(vardata))) > 1:
    #    cont_act = False
    #    try:
    #        log.info(f"Depth = {depth}")
    #        for ini in range(len(depth)):
    #            if np.array(depth)[ini] < 0: continue
    #            elif np.isnan(np.nanmean(np.array(vardata)[:,ini])) or np.array(depth)[ini] > 2 or cont_act: continue
    #            else : cont_act = True
    #            var_moor = np.array(vardata)[:,ini]
    #            depth_moor = depth.data[ini]
    #            vardata_qc = np.array(var_qc)[:,ini]
    #    except Exception as exs:
    #        log.error(f"Pb with depth {exs} {moor} {file}")
    #        continue
    if len(var_moor) == 0 or np.isnan(depth_moor): continue
    #w = np.where(vardata_qc != 1.)
    #var_moor[w[0]] = np.nan
    vardata = var_moor
    if np.isnan(np.nanmean(vardata)) == True: continue


    # ****************************************************************************

    ilon = ind_dict[moor]['ind_lon']
    ilat = ind_dict[moor]['ind_lat']
    #w = np.where(abs(depth_mod-depth_moor[0]) == np.nanmin(abs(depth_mod-depth_moor[0])))
    depth_mod_arr = np.array(depth_mod)
    depth_moor_arr = np.array(depth_moor)
    log.info (f'Mooring {moor} depth_mod {depth_mod} depth_moor {depth_moor}')
    w = np.where(np.abs(depth_mod_arr - depth_moor_arr[0]) == \
            np.nanmin(np.abs(depth_mod_arr - depth_moor_arr[0])))

    if np.isnan(depth_moor[0]): ind_depth = 0
    else: ind_depth = depth_mod[w[0][0]]

    if tstp == 'daily':
        if multidim: ds = mfdataset_hdct.sel(x=ilon, y=ilat, deptht=ind_depth)
        else: ds = mfdataset_hdct.sel(x=ilon, y=ilat)
        time = ds.variables['time_counter'][:].values
        values_var = ds.variables[variable][:].values

    if old_obs == 'old': time = time_mod
    vtime = time.astype('M8[ms]').astype('O')
    stt_date = vtime[0].strftime('%Y%m%d')
    end_date = vtime[-1].strftime('%Y%m%d')
    vect_time = []
    for t in range(len(vtime)):
        if tstp == 'hourly':
            vect_time.append(vtime[t].strftime('%Y%m%d%H'))
        elif tstp == 'daily' and vtime[t].strftime('%Y%m%d') not in vect_time:
            vect_time.append(vtime[t].strftime('%Y%m%d'))
    ndays = len(vect_time)
    vector_time = np.zeros((ndays))
    for il_ind, day in enumerate(np.array(vect_time)):
        if tstp == 'hourly':
            vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d%H').toordinal()-dateCNESref)*24+int(day[8:10])
        elif tstp == 'daily':
            vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref)*24
    if tstp == 'hourly':
        ind_time = []
        for timevalue in time:
            index_time = np.argmin(np.abs(time_mod-timevalue))
            ind_time.append(time_mod[index_time])
        if len(forecast) > 0:
            ind_time_fcst = {}
            vt_fcst = {}
            fcst_hour = []
            for fc in forecast:
                if fc == 0: fcst_hour.append(0)
                elif fc == 1: fcst_hour.append(12)
                else: fcst_hour.append(12 + (fc-1) * 24)
                ind_time_fcst_tmp = []
                vt_fcst_tmp = []
                for timevalue in time:
                    index_time_fcst = np.argmin(np.abs(time_fcst[str(fc)]-timevalue))
                    ind_time_fcst_tmp.append(time_fcst[str(fc)][index_time_fcst])
                ind_time_fcst[str(fc)] = ind_time_fcst_tmp
                for t in range(len(time_fcst[str(fc)])):
                    vt_fcst_tmp.append(pd.to_datetime(str(time_fcst[str(fc)][t])).strftime('%Y%m%d%H'))
                vt_fcst[str(fc)] = vt_fcst_tmp
        values_var = np.nan*np.zeros((len(vector_time), len(forecast)+1))
        if multidim: ds = mfdataset_hdct.sel(x=ilon, y=ilat, time_counter=np.array(ind_time), deptht=ind_depth)
        else: ds = mfdataset_hdct.sel(x=ilon, y=ilat, time_counter=np.array(ind_time))
        values_var[:,0] = ds.variables[variable][:].values
        if len(forecast) > 0:
            for fc,fcst in enumerate(forecast):
                try:
                    meminfo = psutil.Process().memory_info().rss / 2**20
                    log.debug("RSS memory information : {} ".format(str(meminfo)))
                    mfd_fcst = mfdataset_fcst[str(fcst)]
                    if multidim: ds_fcst = mfd_fcst.sel(x=ilon, y=ilat, \
                                           time_counter=np.array(ind_time_fcst[str(fcst)]), \
                                           deptht=ind_depth)
                    else: ds_fcst = mfd_fcst.sel(x=ilon, y=ilat, \
                                                 time_counter=np.array(ind_time_fcst[str(fcst)]))
                    values_var[:,fc+1] = ds_fcst.variables[variable][:].values
                    meminfo = psutil.Process().memory_info().rss / 2**20
                except Exception as exs:
                    log.error("Pb during mfdataset construction fcst :%s " %(exs))
                    log.error("Create mfdadaset FCST NOK {}".format(fc))
                    raise
                for tc, timec in enumerate(vect_time):
                    w = np.where(np.array(vt_fcst[str(fcst)]) == timec) 
                    if len(w[0]) == 0:
                        values_var[tc,fc+1] = np.nan

    #end_time = tt.time()
    #log.info("--- %s seconds ---" % (end_time - start_time))

    # ~~~~~~~~~~~~~ Save the Class2 (model/mooring) in a netcdf file ~~~~~~~~~~~~~~~~~~
    if (tstp == 'hourly' and np.isnan(np.nanmean(values_var[:,0])) == True) or \
       (tstp == 'daily' and np.isnan(np.nanmean(values_var)) == True): continue
    w_nan = np.where(np.isnan(values_var)==True)
    if len(w_nan) > 0:
        values_var[w_nan] = missing_value

    if tstp == 'hourly':
        if len(forecast) > 0:
            log.info(f"Write Moor {nc_file_out} type{depth_moor}")
            write_data_json_file(json_file_out, lat_value, lon_value, depth_moor, values_var, vector_time, \
                                  depth_data_all, value_data_all, vardata_qc, typemoor, ech_fcst = \
                                  np.insert(np.array(fcst_hour),0,0))
            write_data_colloc_files(nc_file_out, lat_value, lon_value, values_var, vector_time, \
                                    stt_date, end_date, depth_moor, missing_value, ech_fcst = \
                                    np.insert(np.array(fcst_hour),0,0))
        else: write_data_colloc_files(nc_file_out, lat_value, lon_value, values_var, vector_time, \
                                      stt_date, end_date, depth_moor, missing_value)
        del nc_file_out, lat_value, lon_value, vardata, values_var, vector_time
    elif tstp == 'daily':
        write_data_colloc_files_daily(nc_file_out, lat_value, lon_value, values_var, vector_time, \
                                      stt_date, end_date, depth_moor, ind_depth, missing_value)
        del nc_file_out, lat_value, lon_value, values_var, vector_time, depth_moor, ind_depth

comm.Barrier()
log.info ("End of Program")
