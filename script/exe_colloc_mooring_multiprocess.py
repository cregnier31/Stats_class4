import matplotlib
matplotlib.use('TkAgg')
import os, sys, getopt
sys.path.append('/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/script/')
sys.path.append('../python_modules/')
sys.path.append('../postraitement/python/module/')
import resource
from mpi4py import MPI
from Logger import Logger
import numpy as np
import xarray as xr
from glob import glob
import pandas as pd
from scipy.spatial import cKDTree
import netCDF4
import datetime as dt
from dateutil.relativedelta import relativedelta
import dask
import arithm


# *************************************************************************************
#
#   Ce programme permet de generer les CLASS2 (modele sur les points de mouillage)
#                            sous format netCDF 
#
# *************************************************************************************


# ~~~~~~~~~~~~~~~ Define creation of netCDF file or timeseries plot ~~~~~~~~~~~~~~~~~~~

nc_file = True

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#                                  FUNCTIONS
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


def compute_last_day_month(y,m):  
    return (dt.date(y+m/12,m%12+1,1)-dt.date(y,m,1)).days

def lon_lat_to_cartesian(lon, lat, R = 1):
    """
     calculates lon, lat coordinates of a point on a sphere with
     radius R
    """
    lon_r = np.radians(lon)
    lat_r = np.radians(lat)
    x =  R * np.cos(lat_r) * np.cos(lon_r)
    y = R * np.cos(lat_r) * np.sin(lon_r)
    z = R * np.sin(lat_r)
    return x,y,z


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


def read_moor(file):
    ncdata = xr.open_dataset(file)
    variables = ncdata.data_vars
    ll_temp = False
    if 'TEMP' in variables.keys():
        ll_temp = True
        temp = ncdata['TEMP']
        temp_qc = ncdata['TEMP_QC']
    else:
        temp = None
        temp_qc = None
    if 'DEPH' in ncdata.variables.keys():
        depth = ncdata['DEPH'][0]
        var_qc=[ var for var in ncdata.variables.keys() if var.startswith('DEP') and var.endswith('QC')] 
        depth_qc = ncdata[var_qc].values
    elif 'PRES' in variables.keys():
        depth = ncdata['PRES'][0]
        depth_qc = ncdata['PRES_QC'][0]
    else:
        print ('Missing Values DEPH or PRES')
        sys.exit(1)

    lon = ncdata['LONGITUDE']
    lat = ncdata['LATITUDE']
    time = ncdata['TIME'].values
    lon_value = np.nanmean(lon)
    lat_value = np.nanmean(lat)

    return lon_value, lat_value, depth, depth_qc, time, temp, ll_temp, temp_qc


def read_pos(filename):
    nc = netCDF4.Dataset(filename,'r')
    variable = 'nav_lon'
    rla_lon = nc.variables[variable][:]
    variable = 'nav_lat'
    rla_lat = nc.variables[variable][:]
    return rla_lon,rla_lat


def read_depth(filename):
    nc = netCDF4.Dataset(filename,'r')
    variable = 'deptht'
    rla_depth = nc.variables[variable][:]

    return rla_depth


def write_data_colloc_files_daily(filename, latitude, longitude, var_mod, vtime, d_moor, d_mod):
    

    nc = netCDF4.Dataset(filename, 'w')

    #  ********************** Add dimensions ************************
        
    nc.createDimension('time', len(vtime))

    #  ********************** Add variables ************************

    nc_model = nc.createVariable('TS_hindcast', 'f', ('time'))
    nc_model.long_name = 'Sea surface temperature computed with the PSY4V3R1 system'
    nc_model.units = 'degrees_C'
    nc.variables['TS_hindcast'][:] = var_mod

    nc_time = nc.createVariable('time','f', ('time'))
    nc_time.calendar = 'gregorian'
    nc_time.standard_name = 'time'
    nc_time.units = 'hours since 1950-01-01 00:00:00'
    nc_time.axis = 'T'
    nc.variables['time'][:] = vtime
   
    #  ********************** Add global attributes ************************

    nc.longitude_east = longitude
    nc.latitude_north = latitude
    nc.depth_mooring = d_moor
    nc.depth_model = d_mod

    nc.close()



def write_data_colloc_files(filename, latitude, longitude, var_moor, var_mod, vtime):
    

    nc = netCDF4.Dataset(filename, 'w')

    #  ********************** Add dimensions ************************
        
    nc.createDimension('time', len(vtime))

    #  ********************** Add variables ************************

    nc_moor = nc.createVariable('TS_mooring', 'f', ('time'))
    nc_moor.long_name = 'Sea surface temperature observed at the mooring'
    nc_moor.units = 'degrees_C'
    nc.variables['TS_mooring'][:] = var_moor
    nc_model = nc.createVariable('TS_hindcast', 'f', ('time'))
    nc_model.long_name = 'Sea surface temperature computed with the PSY4V3R1 system'
    nc_model.units = 'degrees_C'
    nc.variables['TS_hindcast'][:] = var_mod

    nc_time = nc.createVariable('time','f', ('time'))
    nc_time.calendar = 'gregorian'
    nc_time.standard_name = 'time'
    nc_time.units = 'hours since 1950-01-01 00:00:00'
    nc_time.axis = 'T'
    nc.variables['time'][:] = vtime
   
    #  ********************** Add global attributes ************************

    nc.longitude_east = longitude
    nc.latitude_north = latitude
    nc.close()

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
keywords = ['year=', 'month=', 'tstp=']
cla_opts = getopt.getopt(sys.argv[1:],letters,keywords)

for o,p in cla_opts[0]:
    if o in ['-y','--year']:
        YEAR = int(p)
    elif o in ['-m','--month']:
        MONTH = int(p)
    elif o in ['-t','--tstp']:
        tstp = str(p)


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Define the time period ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

if MONTH < 10: MONTH2 = '0'+str(MONTH)
else: MONTH2 = str(MONTH)
DAY = compute_last_day_month(YEAR,MONTH)
dt_start = dt.date(YEAR,MONTH,1)
dt_end = dt.date(YEAR,MONTH,DAY)
ndays = (dt_end - dt_start).days + 1
ts = np.array([dt_start + dt.timedelta(i) for i in xrange(ndays)])


# ~~~~~~~~~~~~~~~~~~~~~~~~ Define configuration (path, date, etc.) ~~~~~~~~~~~~~~~~~~~~

level = 2
log = Logger('TEP_CLASS2').run(level)
coordinates = '/kara/data1/cszczypta/CLASS2/metadata/PSY4V3R1_mask.nc'
ZONE = 'GL'
DIRDATA = '/dataref/opr/DATA/INSITU/HYDRO/NRT/INSITU_GLO_NRT_OBSERVATIONS_013_030/monthly/mooring/'
if tstp == 'hourly':
    variable = 'sotemper'
elif tstp == 'daily':
    variable = 'votemper'
nb_ptsinterp =  1
system = 'PSY4V3R1'
dirdata_mod = '/sortref/opr/pgn/PSY4/psy4v3r1/'
path_data = '/kara/data1/cszczypta/CLASS2/OUTPUTS/DATA/'
dateCNESref   = dt.datetime.strptime('1950010100','%Y%m%d%H').toordinal()


# ~~~~~~~~~~~~~~~~~~~ Read model grid point coordinates (lat/lon) ~~~~~~~~~~~~~~~~~~~~~

lon_mod, lat_mod = read_pos(coordinates)


# ******************************** SPATIAL COLLOCATION *********************************

ind_dict ={}

# ~~~~~~~~ Read mooring coordinates and compute 2D collocation with the model grid ~~~~~~~~~

nb_files = len(glob(DIRDATA+str(YEAR)+str(MONTH2)+'/'+ZONE+'_'+str(YEAR)+str(MONTH2)+'*.nc'))
list_lat_lon = np.nan*np.zeros((nb_files,2))
list_mooring = []
for f, file in enumerate(glob(DIRDATA+str(YEAR)+str(MONTH2)+'/'+ZONE+'_'+str(YEAR)+str(MONTH2)+'*.nc')):
      
    moor =  os.path.basename(file).split('_')[4].split('.')[0]
    list_mooring.append(moor)
    ind_dict[moor] = {}           
    lon_value, lat_value, depth, depth_qc, time, temp, ll_temp, temp_qc = read_moor(file)
    list_lat_lon[f,0] = lat_value
    list_lat_lon[f,1] = lon_value
    ind_dict[moor]['lat'] = lat_value
    ind_dict[moor]['lon'] = lon_value   

ilat, ilon, dist = coloc_2D(lon_mod, list_lat_lon[:,1], lat_mod, list_lat_lon[:,0],
                            nb_ptsinterp, log)

for i in range(len(ilat)):
    ind_dict[list_mooring[i]]['ind_lat'] = ilat[i]
    ind_dict[list_mooring[i]]['ind_lon'] = ilon[i]


# ******************************** CREATE NETCDF FILE *********************************

if nc_file:
  
    # ~~~~~~~~~~~~~~~~~~~ Select model files for the considered month ~~~~~~~~~~~~~~~~~~~~~~~~~~

    liste_file = []
    for t in ts:
        if tstp == 'hourly':
            file_mod  = glob(dirdata_mod+str(YEAR)+'/*/'+system+'_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')
        elif tstp == 'daily':
            file_mod  = glob(dirdata_mod+str(YEAR)+'/*/'+system+'_1dAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')              
        if len(file_mod) == 0:
            if tstp == 'hourly':
                file_mod  = glob(dirdata_mod+str(YEAR+1)+'/*/'+system+'_1hAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')
            if tstp == 'daiy':
                file_mod  = glob(dirdata_mod+str(YEAR+1)+'/*/'+system+'_1dAV_'+t.strftime('%Y%m%d')+'*gridT*.nc')     
        if len(file_mod) > 0 and file_mod[0] not in liste_file:
            liste_file.append(file_mod[0])

    depth_mod = read_depth(liste_file[0])
    mfdataset = xr.open_mfdataset(liste_file, concat_dim='time_counter', autoclose=True)   
    time_mod = mfdataset.variables['time_counter'][:].values
    
    
    # ~~~~~~~~ Read mooring coordinates and compute 2D collocation with the model grid ~~~~~~~~~
    
    list_file = []
    for file in glob(DIRDATA+str(YEAR)+str(MONTH2)+'/'+ZONE+'_'+str(YEAR)+str(MONTH2)+'*.nc'):
        list_file.append(file)


    # *********** repartition dates sur processeurs ***********

    comm = MPI.COMM_WORLD
    nmoor = len(list_file)
    irest  = np.mod(nmoor,comm.size)
    ntask  = nmoor / comm.size
    istart = ntask*comm.rank
    iend   = istart + ntask - 1
    cla_mr = list_file[istart:iend+1]
    iend_tot = ntask*comm.size-1
    if irest > 0 and comm.rank < irest:
        cla_mr.append(list_file[iend_tot+comm.rank+1])

    for file in cla_mr:
        moor =  os.path.basename(file).split('_')[4].split('.')[0]

        print 'Mooring: '+moor

        if tstp == 'hourly':
            nc_file_out = path_data+'Class2_'+system+'_'+moor+'_'+str(YEAR)+MONTH2+'.nc'
        elif tstp == 'daily':
            nc_file_out = path_data+'Class2_mod_daily_'+system+'_'+moor+'_'+str(YEAR)+MONTH2+'.nc'

        lon_value, lat_value, depth, depth_qc, time, temp, ll_temp, temp_qc = read_moor(file)

        if len(np.shape(np.array(temp))) > 1: 
            w = np.where(np.array(depth.data) >= 0)
            if len(w[0]) > 0:
                temp = np.array(temp)[:,w[0][0]]
                temp_qc = np.array(temp_qc)[:,w[0][0]]
                depth_moor = depth.data[w[0][0]]
            else : ll_temp = False
        if not ll_temp: continue

        w = np.where(temp_qc != 1)
        temp[w[0]] = np.nan

        if np.isnan(np.nanmean(temp)) == True: continue

        # ****************************************************************************

        ilon = ind_dict[moor]['ind_lon']
        ilat = ind_dict[moor]['ind_lat']

        w = np.where(abs(depth_mod-depth_moor) == np.nanmin(abs(depth_mod-depth_moor)))
        ind_depth = depth_mod[w[0][0]]

        if tstp == 'daily':
            ds = mfdataset.sel(x=ilon, y=ilat, deptht=ind_depth)
            time = ds.variables['time_counter'][:].values

        vtime = time.astype('M8[ms]').astype('O')
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

        ndays = len(vect_time)
        vector_time = np.zeros((ndays))
        for il_ind, day in enumerate(np.array(vect_time)):
            if tstp == 'hourly':
                vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d%H').toordinal()-dateCNESref)*24+int(day[8:10])
            elif tstp == 'daily':
                vector_time[il_ind] = (dt.datetime.strptime(day,'%Y%m%d').toordinal()-dateCNESref)*24

        if tstp == 'hourly':
            ds = mfdataset.sel(x=ilon, y=ilat, time_counter=np.array(ind_time), deptht=ind_depth)

        values_temp = ds.variables[variable][:].values
                      
      
        # ~~~~~~~~~~~~~ Save the Class2 (model/mooring) in a netcdf file ~~~~~~~~~~~~~~~~~~
        
        if np.isnan(np.nanmean(values_temp)) == True: continue

        if tstp == 'hourly':
            write_data_colloc_files(nc_file_out, lat_value, lon_value, temp, values_temp, vector_time)  
            del nc_file_out, lat_value, lon_value, temp, values_temp, vector_time
        elif tstp == 'daily':
            write_data_colloc_files_daily(nc_file_out, lat_value, lon_value, values_temp, vector_time, depth_moor, ind_depth)  
            del nc_file_out, lat_value, lon_value, values_temp, vector_time, depth_moor, ind_depth
                
    comm.Barrier()
