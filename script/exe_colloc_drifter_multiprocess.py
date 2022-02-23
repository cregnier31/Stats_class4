# @Authors: "C. Szczypta & C.Regnier
import os, sys, getopt
import resource
from mpi4py import MPI
sys.path.append('../../modules/')
from Logger import Logger
import numpy as np
import xarray as xr
#import dask
from glob import glob
import datetime as dt
from timeit import default_timer as timer
import vertical
import time as timecounter
from reader import read_pos, read_pos_reg, read_drifter, read_drifter_pos, read_pos_clim
from utils import compute_last_day_month, find_index_month
from interpolate import search_orca, search_regular
from writer import write_data_colloc_files, write_cl4_files
from loader_post import load_param
from geojson import FeatureCollection, dump
from geomlib import CheckDistance
from Interp_kdtree import interp_KDtree
import cl4errors as cl4err

if sys.version_info[0] >= 3:
    import pickle
else:
    import cPickle
    import pickle



# ********************************************************************************************
#
#   Ce programme permet de collocaliser les sorties du modele sur les donnees des drifters
#         sous format netCDF puis de tracer les series temporelles associees 
#
# ********************************************************************************************


# ~~~~~~~~~~~~~~~ Define creation of netCDF file or timeseries plot ~~~~~~~~~~~~~~~~~~~

nc_file = True
ll_check = False
#=True
features_hdct = []
features_smoc = []
features_clim = []

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
letters = 'y:m'
keywords = ['year=', 'month=', 'system=']
cla_opts = getopt.getopt(sys.argv[1:],letters,keywords)

for o,p in cla_opts[0]:
    if o in ['-y','--year']:
        YEAR = int(p)
    elif o in ['-m','--month']:
        MONTH = int(p)
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
dateCNESref   = dt.datetime.strptime('1950010100','%Y%m%d%H').toordinal()
log.debug("Launch interpolation for %s %s" %(str(YEAR),str(MONTH2)))


#~~~~~~~~~~~~~~~~~~~~ Read Config file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
deb_file = '../cfg/config_'+SYSTEM+'_UV.cfg'
params_dict = load_param(deb_file)
system =  params_dict['system']
systemh = params_dict['systemh']
nb_fcst = int(params_dict['nb_fcst'])
nb_fcst2 = int(params_dict['nb_fcst_smoc'])
nb_pers = int(params_dict['nb_pers'])
model =   params_dict['model']
path_data = params_dict['path_data']
dirdata_smoc = params_dict['dirdata_smoc']
coord_clim = params_dict['coordinates_clim']
dirdata_mod = params_dict['dirdata_mod']
dirdata_mod_weekly = params_dict['dirdata_mod_weekly']
dirout = params_dict['dirout']

# ~~~~~~~~~~~~~~~~~~~ Read model grid point coordinates (lat/lon) ~~~~~~~~~~~~~~~~~~~~~
comm = MPI.COMM_WORLD
for num_proc in range(comm.size):
    if comm.rank == num_proc:
        log.debug("Read model grid point coordinates")
        try:
            lon_mod, lat_mod = read_pos(params_dict['coordinates'], log)
            mod_coord = xr.open_dataset(params_dict['coordinates'])
            log.debug("Read ok")
        except IOError:
            log.error("Open Error coordinates")
            sys.exit(1)
        try:
            lon_mod_reg, lat_mod_reg = read_pos_reg(params_dict['coordinates_reg'])
            log.debug("Read ok reg")
        except IOError:
            log.error("Open Error coordinates_reg")
            sys.exit(1)
        try:
            lon_clim, lat_clim = read_pos_clim(params_dict['coordinates_clim'])
            log.debug("Read ok clim")
        except IOError:
            log.error("Open Error climatology")

        #else:
        #    print("Unexpected error:", sys.exc_info()[0])
        #    raise Exception
        # ******************************** SPATIAL COLLOCATION *********************************

        ind_dict ={}

        # ~~~~~~~~ Read drifter coordinates and compute 2D collocation with the model grid ~~~~~~~~~

        log.debug("Read drifter coordinates and interpolate")
        DIRDATA = params_dict['DIRDATA']
        ZONE = params_dict['ZONE']
        TYPE = params_dict['TYPE']
        SUFFIX = params_dict['SUFFIX']
        if TYPE == "013_030":
           frame = ZONE+'_'+str(YEAR)+str(MONTH2)+'_'+SUFFIX+'*.nc' 
        elif TYPE == "013_048":
           frame = ZONE+'_'+SUFFIX+'*'+str(YEAR)+str(MONTH2)+'.nc' 
        nb_files = len(glob(DIRDATA+str(YEAR)+str(MONTH2)+'/'+frame))
        list_lat_lon = np.nan*np.zeros((nb_files,2))
        list_drifters = []
        list_lon = []
        list_lat = []
        list_drift = []
        list_file = []
        #start = timer()
        for f, file in enumerate(glob(DIRDATA+str(YEAR)+str(MONTH2)+'/'+frame)):
            list_file.append(file)
            if TYPE == "013_030":
                drifter =  os.path.basename(file).split('_')[4].split('.')[0]
            elif TYPE == "013_048":
                drifter =  os.path.basename(file).split('_')[3].split('.')[0]
            list_drifters.append(drifter)
            ind_dict[drifter] = {}
            lon_value, lat_value = read_drifter_pos(file)
            list_lon.extend(lon_value)
            list_lat.extend(lat_value)
            for i in range(len(lon_value)):
                list_drift.append(drifter)

        log.debug("Read drifter OK")
        # end = timer()
        #log.debug('~~~~~~~~ Time elapsed Read : %s %s' %
        #                (str(end - start), " seconds ~~~~~~~~~~~~"))

        # ~~~~~~~~ Interpolate drifters positions on orca grid ~~~~~~~~~

        nb_ptsinterp = int(params_dict['nb_ptsinterp'])
        DIR_INTERP = params_dict['DIR_INTERP']
        weight_file = DIR_INTERP+'weight_file_'+str(nb_ptsinterp)+'pts_'+str(nb_files)+'drifters_'+str(YEAR)+"_"+str(MONTH2)+".nc"
        #start = timer()
        save=False
        TreeObj = interp_KDtree(log)
        log.debug('Interpolate on irregular grid')
        dist, idw = TreeObj.tree_and_query(lon_mod, lat_mod, \
                                               np.array(list_lon), np.array(list_lat),\
                                               nb_ptsinterp, weight_file=weight_file, save=save)
        # ~~~~~~~~ Interpolate drifters positions on regular grid ~~~~~~~~~

        log.debug('Interpolate on regular grid')
        weight_file = DIR_INTERP+'weight_file_regular_'+str(nb_ptsinterp)+'pts_'+str(nb_files)+'drifters_'+str(YEAR)+"_"+str(MONTH2)+".nc"
        TreeObj = interp_KDtree(log)
        dist_reg, idw_reg = TreeObj.tree_and_query(lon_mod_reg, lat_mod_reg,\
                                                   np.array(list_lon), np.array(list_lat),\
                                                   nb_ptsinterp, weight_file=weight_file, save=save)
        # ~~~~~~~~ Interpolate drifters positions on clim regular grid ~~~~~~~~~

        log.debug('Interpolate on regular grid clim')

        TreeObj = interp_KDtree(log)
        weight_file = DIR_INTERP+'weight_file_regular_clim_'+str(nb_ptsinterp)+'pts_'+str(nb_files)+'drifters_'+str(YEAR)+"_"+str(MONTH2)+".nc"
        dist_clim, idw_clim  = TreeObj.tree_and_query(lon_clim, lat_clim,
                                                      np.array(list_lon), np.array(list_lat),\
                                                      nb_ptsinterp, weight_file=weight_file, save=save)
        #end = timer()
        #log.debug('~~~~~~~~ Time elapsed coloc : %s %s' %
        #            (str(end - start), " seconds ~~~~~~~~~~~~"))
        log.debug('Process Coloc terminated')

comm.Barrier()

# ******************************** CREATE NETCDF FILE *********************************

log.info('Creation of CLASS4 file')

if nc_file:

    # *********** repartition dates sur processeurs ***********


    comm = MPI.COMM_WORLD
    if comm.size > 1 :
        ndrift = len(list_file)
        irest  = np.mod(ndrift,comm.size)
        ntask  = ndrift // comm.size
        istart = ntask*comm.rank
        iend   = istart + ntask - 1
        cla_df = list_file[istart:iend+1]
        iend_tot = ntask*comm.size-1
        log.info("Nb drifters {}".format(ndrift))
        log.info("istart {} iend {}".format(istart, iend))
        log.info("Nb tasks {}".format(ntask))
        log.info("cla_df {} iend {}".format(cla_df, iend))
        if irest > 0 and comm.rank < irest:
            log.info("irest > 0 comm.rank < irest ; irest comm.rank {} {}".format(irest,comm.rank))
            cla_df.append(list_file[iend_tot+comm.rank+1])
    else:
        cla_df = list_file
    for file in cla_df:
        log.debug('')
        if TYPE == "013_030":
           drifter =  os.path.basename(file).split('_')[4].split('.')[0]
        elif TYPE == "013_048":
           drifter =  os.path.basename(file).split('_')[3].split('.')[0]
        log.debug('Drifter : %s' %(drifter))
        #Find indice in a list
        index_drift = [i for i,val in enumerate(list_drift) if val==drifter]
        list_drift_2 = np.array(list_drift)[index_drift]
        ## get ilat /ilon
        #start = timer()
        ilat_reg, ilon_reg = search_regular(idw_reg[index_drift], lon_mod_reg, lat_mod_reg)
        ilat_clim, ilon_clim = search_regular(idw_clim[index_drift], lon_clim, lat_clim)
        ilat, ilon = search_orca(idw[index_drift], lon_mod, lat_mod)
        #end = timer()
        #log.debug('~~~~~~~~ Time search : %s %s' %
        #            (str(end - start), " seconds ~~~~~~~~~~~~"))
        ## read drifter value
        try:
            lon_value, lat_value, depth, depth_qc, time, u_ewct, v_nsct,\
                    ll_var, u_qc, v_qc, wind_u, wind_v, current_test, \
                    current_test_qc, position_qc, time_qc, dc_reference = read_drifter(file)
        except:
            raise cl4err.Class4FatalError("Pb with drifter file {}".format(file))  
        w_depth15 = np.where(np.array(depth) == 15.)
        ndim1, ndim2 = np.shape(depth)
        w_depth0= np.array([ i for i in np.arange(0,ndim1)])
        #w_depth0 = np.where(np.array(depth) == 0.)
        if w_depth0.size > 0:
           # ind_x0 = w_depth0[0]
           # ind_y0 = w_depth0[1]
            u_ewct0 = np.array(u_ewct)[w_depth0, 0]
            v_nsct0 = np.array(v_nsct)[w_depth0, 0]
            u_qc0 = np.array(u_qc)[w_depth0, 0]
            v_qc0 = np.array(v_qc)[w_depth0, 0]
            depth0 = np.array(depth)[w_depth0, 0]
            depth_qc0 = np.array(depth_qc)[w_depth0, 0]
            current_test_qc0 = np.array(current_test_qc)[w_depth0, 0]
            current_test0 = np.array(current_test)[w_depth0, 0]
            ll_var0 = True
        else:
            print ("Missing first level %s" %(file))
            ll_var0 = False

        if len(w_depth15[0]) > 0:
            ind_x15 = w_depth15[0]
            ind_y15 = w_depth15[1]
            u_ewct15 = np.array(u_ewct)[ind_x15, ind_y15]
            v_nsct15 = np.array(v_nsct)[ind_x15, ind_y15]
            u_qc15 = np.array(u_qc)[ind_x15, ind_y15]
            v_qc15 = np.array(v_qc)[ind_x15, ind_y15]
            depth15 = np.array(depth)[ind_x15, ind_y15]
            depth_qc15 = np.array(depth_qc)[ind_x15, ind_y15]
            current_test_qc15 = np.array(current_test_qc)[ind_x15, ind_y15]
            current_test15 = np.array(current_test)[ind_x15, ind_y15]
            if len(np.shape(wind_u)) > 0 and len(np.shape(wind_v)) > 0:
                u_wind = np.array(wind_u)[:,0]
                v_wind = np.array(wind_v)[:,0]
            else:
                print ("Missing_wind %s" %(file))
                nb_times, nb_depths = np.shape(u_ewct)
                u_wind = np.nan*np.zeros(nb_times)
                v_wind = np.nan*np.zeros(nb_times)
            if len(w_depth15[0]) != ndim1:
                log.error("Missing some depth at 15m depth")
                log.error("file %s" %(file))
            ll_var15 = True
        else: ll_var15 = False
        if not ll_var15: continue
        # ****************************************************************************

        vtime = time.astype('M8[ms]').astype('O')
        vect_time = []
        vect_time_d = []
        for t in range(len((w_depth15[0]))):
            vect_time.append(vtime[t].strftime('%Y%m%d%H'))
            vect_time_d.append(vtime[t].strftime('%Y%m%d'))
        ndays = len(vect_time)
        vector_time = np.nan*np.zeros((ndays))
        for il_ind, day in enumerate(np.array(vect_time)):
            vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d%H').toordinal()-dateCNESref)*24+int(day[8:10])

        valu = []
        valv = []
        ## Value to interpolate drifter
        interp_depth = 15.0
        list_ordered = sorted(set(vect_time_d))
        ## Todo MPI sur les jours
        for ind1, value in enumerate(list_ordered):
            #start2 = timer()
            nc_file_out = path_data+'Class2_'+system+'_'+drifter+'_'+str(value)+'.nc'
            indexes = [i for i,val in enumerate(vect_time_d) if val==value]
            id_drift = np.nan*np.zeros((len(indexes),), dtype=int)
            ilat_val = [ int(ilat[i])  for i in indexes]
            ilon_val = [ int(ilon[i])  for i in indexes]
            ilat_val_reg = [ int(ilat_reg[i])  for i in indexes]
            ilon_val_reg = [ int(ilon_reg[i])  for i in indexes]
            ilat_val_clim = [ int(ilat_clim[i])  for i in indexes]
            ilon_val_clim = [ int(ilon_clim[i])  for i in indexes]
            id_drift = [ int(list_drift_2[i])  for i in indexes]
            ndays = len(indexes)
            ## Number of components U&V
            nb_comp = 2
            ## Number of depths
            nb_profs = 2
            ## Initialize arrays
            DATA_SAVE_obs = np.nan*np.zeros((ndays, nb_comp, nb_profs))
            DATA_SAVE_best = np.nan*np.zeros((ndays, nb_comp, nb_profs))
            DATA_SAVE_clim = np.nan*np.zeros((ndays, nb_comp, nb_profs))
            DATA_SAVE_stokes = np.nan*np.zeros((ndays, nb_comp))
            DATA_SAVE_tides = np.nan*np.zeros((ndays, nb_comp))
            DATA_SAVE_smoc = np.nan*np.zeros((ndays, nb_comp))
            DATA_SAVE_fcst = np.nan*np.zeros((ndays, nb_comp, nb_fcst, nb_profs))
            DATA_SAVE_pers = np.nan*np.zeros((ndays, nb_comp, nb_fcst, nb_profs))
            depth_qc_tmp = np.nan*np.zeros((ndays, nb_profs))
            depth_tmp = np.nan*np.zeros((ndays, nb_profs))
            current_test_qc_tmp = np.nan*np.zeros((ndays, nb_profs))
            current_test_tmp = np.nan*np.zeros((ndays, nb_profs))

            lon_val_tmp = np.nan*np.zeros((ndays))
            lat_val_tmp = np.nan*np.zeros((ndays))
            ## Populate with data values
            if ll_var0:
                log.debug(file)
                DATA_SAVE_obs[:, 0, 0] = u_ewct0[indexes]
                DATA_SAVE_obs[:, 1, 0] = v_nsct0[indexes]
                depth_tmp[:,0] = depth0[indexes]
                depth_qc_tmp[:,0] = depth_qc0[indexes]
                current_test_qc_tmp[:,0] = current_test_qc0[indexes]
                current_test_tmp[:,0] = current_test0[indexes]
            else:
                DATA_SAVE_obs[:, 0, 0] = np.nan
                DATA_SAVE_obs[:, 1, 0] = np.nan
                depth_tmp[:,0] = np.nan
                depth_qc_tmp[:,0] =  np.nan
                current_test_qc_tmp[:,0] = np.nan
                current_test_tmp[:,0] = np.nan

            DATA_SAVE_obs[:, 0, 1] = u_ewct15[indexes]
            DATA_SAVE_obs[:, 1, 1] = v_nsct15[indexes]
            lon_val_tmp[:] = lon_value[indexes]
            lat_val_tmp[:] = lat_value[indexes]
            vector_time_tmp = vector_time[indexes]
            u_qc_tmp = u_qc15[indexes]
            v_qc_tmp = v_qc15[indexes]
            depth_qc_tmp[:,1] = depth_qc15[indexes]
            depth_tmp[:,1] = depth15[indexes]
            current_test_qc_tmp[:,1] = current_test_qc15[indexes]
            current_test_tmp[:,1] = current_test15[indexes]
            u_wind_tmp = u_wind[indexes]
            v_wind_tmp = v_wind[indexes]
            position_qc_tmp = np.nan*np.zeros((ndays))
            position_qc_tmp = position_qc[indexes]
            dc_reference_tmp = np.chararray(ndays, itemsize=32)
            dc_reference_tmp = dc_reference[indexes]
            time_qc_tmp = np.nan*np.zeros((ndays))
            time_qc_tmp = time_qc[indexes]
            ## Loop on leadtimes
            ini = 0
            for ech in range(nb_fcst+nb_pers+1):
                log.debug("Leadtime %i " %(ech))
                if ech == 0:
                    dir_mod = dirdata_mod_weekly
                    system_tmp = systemh
                elif ech > 0 and ech < nb_fcst+1:
                    subpath = 'fcst'+str(ech-1)
                    dir_mod = dirdata_mod+subpath+'/'
                    system_tmp = system
                else:
                    subpath = 'pers'+str(ech-nb_fcst)
                    dir_mod = dirdata_mod+subpath+'/'
                    system_tmp = system

                file_mod_U  = glob(dir_mod+system_tmp+'_1dAV_'+value+'*gridU*.nc')
                file_mod_V  = glob(dir_mod+system_tmp+'_1dAV_'+value+'*gridV*.nc')
                file_SMOC  = glob(dirdata_smoc+'SMOC_'+value+'*.nc')
                log.debug(dir_mod+system_tmp+'_1dAV_'+value+'*gridU*.nc')

                if len(file_mod_U) > 0 and len(file_mod_V) > 0:
                    start = timer()
                    #speed_U = xr.open_dataset(file_mod_U[0])
                    #speed_V = xr.open_dataset(file_mod_V[0])
                    try:
                        speed_U = xr.open_mfdataset(file_mod_U[0],chunks={'time_counter':1,'deptht':'auto','y':'auto','x':'auto'},parallel=True,combine='by_coords')
                        speed_V = xr.open_mfdataset(file_mod_V[0],chunks={'time_counter':1,'deptht':'auto','y':'auto','x':'auto'},parallel=True,combine='by_coords')
                        values_u15 = speed_U.vozocrtx.isel(x=xr.DataArray(ilon_val, dims=['point']),\
                                    y=xr.DataArray(ilat_val, dims=['point']),time_counter=0).values
                        values_v15 = speed_V.vomecrty.isel(x=xr.DataArray(ilon_val, dims=['point']),\
                                    y=xr.DataArray(ilat_val, dims=['point']),time_counter=0).values
                        values_u0 = values_u15[0,:]
                        values_v0 = values_v15[0,:]
		        #values_u0 = speed_U.vozocrtx.isel(x=xr.DataArray(ilon_val, dims=['point']),\
                        #            y=xr.DataArray(ilat_val, dims=['point']),time_counter=0, deptht=0).values
                        #values_v0 = speed_V.vomecrty.isel(x=xr.DataArray(ilon_val, dims=['point']),\
                        #            y=xr.DataArray(ilat_val, dims=['point']),time_counter=0, deptht=0).values
                        depth_modU = speed_U.variables['deptht'][:].values
                        depth_modV = speed_V.variables['deptht'][:].values
                        ndepths, ntimes = np.shape(values_u15)
                        values_u15_interp = np.nan*np.zeros(ntimes)
                        values_v15_interp = np.nan*np.zeros(ntimes)
                    except:
                        log.debug("Pb with file {}".format(file_mod_U[0]))
                        log.debug("Pb with file {}".format(file_mod_V[0]))
                        raise

                    ## Interp current at 15m depth
                    for timestep in range(ntimes):
                        log.debug('   Vertical interpolation    ')
                        fixture = vertical.Column(values_u15[:,timestep], depth_modU[:])
                        values_u15_interp[timestep] = fixture.interpolate(interp_depth)
                        fixture = vertical.Column(values_v15[:,timestep], depth_modV[:])
                        values_v15_interp[timestep] = fixture.interpolate(interp_depth)
                        log.debug(values_u15_interp[timestep])
                        log.debug(values_v15_interp[timestep])
                    ## Populate arrays
                    if ech == 0:
                        log.debug(" Leadtime Hindcast")
                        DATA_SAVE_best[:, 0, 0] = values_u0
                        DATA_SAVE_best[:, 1, 0] = values_v0
                        DATA_SAVE_best[:, 0, 1] = values_u15_interp
                        DATA_SAVE_best[:, 1, 1] = values_v15_interp
			# Check Distance to see if the colocated point is close to the drifter
                        if ll_check:
                            dist, features_h = CheckDistance(mod_coord.nav_lon.isel(x=xr.DataArray(ilon_val, dims=['point']),
	                                         y=xr.DataArray(ilat_val, dims=['point'])).values,
		                                 mod_coord.nav_lat.isel(x=xr.DataArray(ilon_val, dims=['point']),
                                                 y=xr.DataArray(ilat_val, dims=['point'])).values,
                                                 lon_val_tmp, lat_val_tmp, dist_max=10., name="MODEL_"+drifter) 
                            if features_h:
                                list_file = "MODEL_"+drifter+"_HDCT_"+str(dt_start)+".p"
                                with open(dirout+list_file, 'wb') as f:
                                     pickle.dump(features_h,f, pickle.HIGHEST_PROTOCOL)
                    elif ech > 0  and ech <= nb_fcst:
                        log.debug(" Leadtime Forecast")
                        indf = ini-1
                        DATA_SAVE_fcst[:, 0, indf, 0] = values_u0
                        DATA_SAVE_fcst[:, 1, indf, 0] = values_v0
                        DATA_SAVE_fcst[:, 0, indf, 1] = values_u15_interp
                        DATA_SAVE_fcst[:, 1, indf, 1] = values_v15_interp
                    elif ech > nb_fcst:
                        log.debug(" Leadtime Persistence")
                        indp = ini-nb_fcst-1
                        DATA_SAVE_pers[:, 0, indp, 0] = values_u0
                        DATA_SAVE_pers[:, 1, indp, 0] = values_v0
                        DATA_SAVE_pers[:, 0, indp, 1] = values_u15_interp
                        DATA_SAVE_pers[:, 1, indp, 1] = values_v15_interp
                    ##
                    speed_V.close()
                    speed_U.close()
                    end = timer()
                    log.debug("Read Ok {} rank {}".format(value,comm.rank))
                    log.debug('~~~~~~~~ Time elapsed Read : {} {} {}'.format
                             (str(end - start), " seconds ~~~~~~~~~~~~",comm.rank))
                else:
                    log.debug("File not found forecast for date %s %s" %(str(value),str(dir_mod+system_tmp)))
                    log.debug(dir_mod+system_tmp+'_1dAV_'+value+'*gridU*.nc')
                if ech == 0:
                    ## Add climatology from Lumpkin
                    try:
                        CLIM = xr.open_dataset(params_dict['coordinates_clim'])
                    except:
                        log.error("missing clim dataset")
                        log.error(params_dict['coordinates_clim'])
                    index_time=find_index_month(value)
                    if comm.rank == 0 :  log.info("Index time %s" %(str(index_time)))
                    value_uclim0 = CLIM.U.isel(longitude=xr.DataArray(ilon_val_clim, dims=['point']),\
                            latitude=xr.DataArray(ilat_val_clim, dims=['point']),time=index_time-1).values
                    value_vclim0 = CLIM.V.isel(longitude=xr.DataArray(ilon_val_clim, dims=['point']),\
                                latitude=xr.DataArray(ilat_val_clim, dims=['point']),time=index_time-1).values
		    ## Compute selected distance
                    if ll_check:
                        dist, features_c = CheckDistance(CLIM.Lon.isel(longitude=xr.DataArray(ilon_val_clim)).values, \
                                                         CLIM.Lat.isel(latitude=xr.DataArray(ilat_val_clim)).values, \
		                                         lon_val_tmp, lat_val_tmp, dist_max=20., name="CLIM_"+drifter)
                        if features_c:
                            features_clim.extend(features_c)
                            list_file = dirout+"CLIM_"+drifter+"_"+str(dt_start)+".p"
                            with open(list_file, 'wb') as f:
                                pickle.dump(features_c,f, pickle.HIGHEST_PROTOCOL)
                    DATA_SAVE_clim[:, 0, 0] = value_uclim0[:]
                    DATA_SAVE_clim[:, 1, 0] = value_vclim0[:]
                    DATA_SAVE_clim[:, 0, 1] = value_uclim0[:]
                    DATA_SAVE_clim[:, 1, 1] = value_vclim0[:]
                    ##
                    # Add SMOC drift
                    if len(file_SMOC) > 0 :
                        SMOC =  xr.open_dataset(file_SMOC[0])
                        if ll_check:
                            dist, features_s = CheckDistance(SMOC.longitude.isel(longitude=xr.DataArray(ilon_val_reg)).values,\
			                                     SMOC.latitude.isel(latitude=xr.DataArray(ilat_val_reg)).values,\
		                                             lon_val_tmp, lat_val_tmp, dist_max=10., name="SMOC_"+drifter)
                            if features_s:
                                features_smoc.extend(features_s)
                                list_file = "SMOC_"+drifter+"_"+str(dt_start)+".p"
                                with open(dirout+list_file, 'wb') as f:
                                    pickle.dump(features_s,f, pickle.HIGHEST_PROTOCOL)
                        values_u_stokes = SMOC.vsdx.isel(longitude=xr.DataArray(ilon_val_reg, dims=['point']),\
                                    latitude=xr.DataArray(ilat_val_reg, dims=['point']),time=0).values
                        values_vstokes = SMOC.vsdy.isel(longitude=xr.DataArray(ilon_val_reg, dims=['point']),\
                                    latitude=xr.DataArray(ilat_val_reg, dims=['point']),time=0).values
                        values_utide = SMOC.utide.isel(longitude=xr.DataArray(ilon_val_reg, dims=['point']),\
                                    latitude=xr.DataArray(ilat_val_reg, dims=['point']),time=0).values
                        values_vtide = SMOC.vtide.isel(longitude=xr.DataArray(ilon_val_reg, dims=['point']),\
                                    latitude=xr.DataArray(ilat_val_reg, dims=['point']),time=0).values
                        values_usmoc = SMOC.utotal.isel(longitude=xr.DataArray(ilon_val_reg, dims=['point']),\
                                    latitude=xr.DataArray(ilat_val_reg, dims=['point']),time=0).values
                        values_vsmoc = SMOC.vtotal.isel(longitude=xr.DataArray(ilon_val_reg, dims=['point']),\
                                    latitude=xr.DataArray(ilat_val_reg, dims=['point']),time=0).values
                        SMOC.close()
                        DATA_SAVE_stokes[:, 0] = values_u_stokes
                        DATA_SAVE_stokes[:, 1] = values_vstokes
                        DATA_SAVE_tides[:, 0] = values_utide
                        DATA_SAVE_tides[:, 1] = values_vtide
                        DATA_SAVE_smoc[:, 0] = values_usmoc
                        DATA_SAVE_smoc[:, 1] = values_vsmoc
                    else:
                        log.info("Missing file SMOC for date %s" %(value))
                        sys.exit(1)
                ini+=1
            # ~~~~~~~~~~~~~ Save the Class2 (model/mooring) in a netcdf file ~~~~~~~~~~~~~~~~~~
            log.debug('Write file %s %s' %(str(drifter), str(value) ))
            if np.isnan(np.nanmean(DATA_SAVE_best)) == True and np.isnan(np.nanmean(DATA_SAVE_best)) == True: continue
            start = timer()
            write_cl4_files(nc_file_out, lat_val_tmp, lon_val_tmp, id_drift, DATA_SAVE_obs, DATA_SAVE_best,\
                            DATA_SAVE_fcst, DATA_SAVE_pers, DATA_SAVE_stokes, DATA_SAVE_tides, DATA_SAVE_smoc, \
                            vector_time_tmp, u_qc_tmp, v_qc_tmp, depth_tmp, depth_qc_tmp,\
                            current_test_tmp, current_test_qc_tmp, position_qc_tmp,\
                            time_qc_tmp, dc_reference_tmp, u_wind_tmp, v_wind_tmp,\
                            DATA_SAVE_clim, nb_fcst, model, TYPE)
            end = timer()
            log.debug('~~~~~~~~ Time elapsed Write : {} {} {}'.format
                               (str(end - start), " seconds ~~~~~~~~~~~~",comm.rank))
            log.debug('Write file ok %s ' %(nc_file_out))
    comm.Barrier()

log.info('Process terminated rank {}'.format(comm.rank))
sys.stdout.flush()
#if comm.rank == 0 :
#    log.info('Process terminated rank 0 {}'.format(comm.rank))
#    sys.stdout.flush()
#else :
#    log.info('Process terminated rank {}'.format(comm.rank))
#    sys.stdout.flush()
#

