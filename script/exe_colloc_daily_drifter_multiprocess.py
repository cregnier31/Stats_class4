# Program to compute CLASS4 drifters
import numpy as np
import sys
sys.path.append('../../modules/')
# local modules
from Logger import Logger
import datetime as dt
from glob import glob
import os
import getopt
from reader import read_pos, read_drifter, read_pos_clim,\
                   read_pos_reg
from Interp_kdtree import interp_KDtree
import vertical
import cl4errors as cl4err
import pandas as pd
import xarray as xr
from timeit import default_timer as timer
from utils import compute_last_day_month, find_index_month
from loader_post import load_param
from interpolate import search_orca, search_regular
from writer import write_cl4_files
from mpi4py import MPI
from Interpolator import Interpolator
import numpy.ma as ma

def read_mod_and_interp(log, ech, nb_fcst, params_dict,
                        weight,
                        inds,
                        value,
                        nbpts_interp,
                        variableU = "vozocrtx",
                        variableV = "vomecrty",
                        interp_depth=15.0,
                        time = 0):
    interp_class = Interpolator(log)
    if ech == 0:
        dir_mod = params_dict['dirdata_mod_weekly']
        system_tmp = params_dict['systemh']
    elif ech > 0 and ech < nb_fcst + 1:
        subpath = 'fcst' + str(ech - 1)
        dir_mod = params_dict['dirdata_mod'] + subpath + '/'
        system_tmp = params_dict['system']
    else:
        subpath = 'pers' + str(ech - nb_fcst)
        dir_mod = params_dict['dirdata_mod'] + subpath+'/'
        system_tmp = params_dict['system']

    file_mod_U = glob(dir_mod + system_tmp + '_1dAV_' + value
                      + '*gridU*.nc')
    file_mod_V = glob(dir_mod + system_tmp + '_1dAV_' + value
                      + '*gridV*.nc')
    log.debug(dir_mod+system_tmp + '_1dAV_' + value + '*gridU*.nc')
    if not(file_mod_U) and not(file_mod_V):
        log.debug("Files are missing in U and V {dir_mod}{system_tmp}_1dAV_{value}*gridU*.nc")
        sys.exit(1)
    else:
        try:
            speed_U = xr.open_dataset(file_mod_U[0])
            speed_V = xr.open_dataset(file_mod_V[0])
            var_inU = speed_U[variableU]
            var_inV = speed_V[variableV]
            depth_mod = speed_U['deptht'][:].values
            ind_depth1, ind_depth2 = interp_class.\
                    getnearpos(interp_depth, depth_mod)
            w1, w2 = interp_class.getweight(depth_mod[ind_depth1],\
                    depth_mod[ind_depth2], interp_depth)
            var_in1_U = var_inU[time, ind_depth1, :, :].values
            var_in2_U = var_inU[time, ind_depth2, :, :].values
            var_in1_V = var_inV[time, ind_depth1, :, :].values
            var_in2_V = var_inV[time, ind_depth2, :, :].values
            # Surface values
            var_in_U0 = var_inU[time, 0, :, :].values
            var_in_V0 = var_inV[time, 0, :, :].values
            ## 15m values
            if nbpts_interp > 1:
                tab_interp_U0 = np.sum(weight * np.array(var_in_U0).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
                tab_interp_V0 = np.sum(weight * np.array(var_in_V0).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
                # U
                tab_interp_1_U = np.sum(weight * np.array(var_in1_U).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
                tab_interp_2_U = np.sum(weight * np.array(var_in2_U).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
                tab_interp_U = (w1 * tab_interp_1_U) + (w2 * tab_interp_2_U)
                # V
                tab_interp_1_V = np.sum(weight * np.array(var_in1_V).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
                tab_interp_2_V = np.sum(weight * np.array(var_in2_V).flatten()
                                      [inds], axis=1) / np.sum(weight, axis=1)
                tab_interp_V = (w1 * tab_interp_1_V) + (w2 * tab_interp_2_V)
            else:
                tab_interp_U0 = ma.array(var_in_U0).flatten()[inds]
                tab_interp_V0 = ma.array(var_in_V0).flatten()[inds]
                tab_interp_U = (w1 * ma.array(var_in_U0).flatten()[inds]) + \
                               (w2 * ma.array(var_in_U0).flatten()[inds])
                tab_interp_V = (w1 * ma.array(var_in_V0).flatten()[inds]) + \
                               (w2 * ma.array(var_in_V0).flatten()[inds])
        except Exception:
            log.debug(f"Pb with file {file_mod_U}")
            log.debug(f"Pb with file {file_mod_V}")
            raise Exception
        # Interp current at 15m depth
        #start = timer()
        #for timestep in range(ntimes):
        #    fixture = vertical.Column(values_u15[:, timestep], depth_modU[:])
        #    values_u15_interp[timestep] = fixture.interpolate(interp_depth)
        #    fixture = vertical.Column(values_v15[:, timestep], depth_modV[:])
        #    values_v15_interp[timestep] = fixture.interpolate(interp_depth)
        #    # log.debug(values_u15_interp[timestep])
        #    # log.debug(values_v15_interp[timestep])
        #speed_V.close()
        #speed_U.close()
        #end = timer()
        #log.debug(f'   Vertical interpolation Time {end - start}    ')
    return tab_interp_U, tab_interp_V, tab_interp_U0, tab_interp_V0


def read_smoc_and_clim(params_dict,
                       weight_clim,
                       inds_clim,
                       weight_reg,
                       inds_reg,
                       datevalue,
                       nbpts_interp):

    dirdata_smoc = params_dict['dirdata_smoc']
    file_SMOC = glob(dirdata_smoc + 'SMOC_' + datevalue + '*.nc')
    # Add climatology from Lumpkin
    try:
        CLIM = xr.open_dataset(params_dict['coordinates_clim'])
    except IOError as e:
        log.error(f"missing clim dataset {e}")
        log.error(params_dict['coordinates_clim'])
        raise IOError(e)
    index_time = find_index_month(datevalue)
    # if comm.rank == 0 :
    #     log.debug(f"Index time {index_time}")
    log.debug(f"Leadtime Clim {index_time-1}")
    # Surface values
    var_in_Uclim = CLIM['U'][index_time-1, :, :].values
    var_in_Vclim = CLIM['V'][index_time-1, :, :].values
    if nbpts_interp > 1:
        value_uclim0 = np.sum(weight_clim * np.array(var_in_Uclim).flatten()
                              [inds_clim], axis=1) / np.sum(weight_clim, axis=1)
        value_vclim0 = np.sum(weight_clim * np.array(var_in_Vclim).flatten()
                              [inds_clim], axis=1) / np.sum(weight_clim, axis=1)
    else:
        #value_uclim0 = ma.array(var_in_Uclim).flatten()[inds_clim]
        value_uclim0 = ma.array(np.transpose(var_in_Uclim)).flatten()[inds_clim]
        #value_vclim0 = ma.array(var_in_Vclim).flatten()[inds_clim]
        value_vclim0 = ma.array(np.transpose(var_in_Vclim)).flatten()[inds_clim]

    # Add SMOC drift
    if len(file_SMOC) > 0:
        SMOC = xr.open_dataset(file_SMOC[0])
        var_in_Ustokes = SMOC['vsdx'][0, :, :].values
        var_in_Vstokes = SMOC['vsdy'][0, :, :].values
        var_in_Utide = SMOC['utide'][0, :, :].values
        var_in_Vtide = SMOC['vtide'][0, :, :].values
        var_in_Usmoc = SMOC['utotal'][0, :, :].values
        var_in_Vsmoc = SMOC['vtotal'][0, :, :].values
        if nbpts_interp > 1:
            values_u_stoke = np.sum(weight_reg * np.array(var_in_Ustokes).flatten()
                                  [inds_reg], axis=1) / np.sum(weight_reg, axis=1)
            values_v_stoke = np.sum(weight_reg * np.array(var_in_Vstokes).flatten()
                                  [inds_reg], axis=1) / np.sum(weight_reg, axis=1)
            values_u_tide = np.sum(weight_reg * np.array(var_in_Utide).flatten()
                                  [inds_reg], axis=1) / np.sum(weight_reg, axis=1)
            values_v_tide = np.sum(weight_reg * np.array(var_in_Vtide).flatten()
                                  [inds_reg], axis=1) / np.sum(weight_reg, axis=1)
            values_u_smoc = np.sum(weight_reg * np.array(var_in_Usmoc).flatten()
                                  [inds_reg], axis=1) / np.sum(weight_reg, axis=1)
            values_v_smoc = np.sum(weight_reg * np.array(var_in_Vsmoc).flatten()
                                  [inds_reg], axis=1) / np.sum(weight_reg, axis=1)
        else:
            values_u_stokes = ma.array(var_in_Ustokes).flatten()[inds_reg]
            values_v_stokes = ma.array(var_in_Vstokes).flatten()[inds_reg]
            values_u_tide = ma.array(var_in_Utide).flatten()[inds_reg]
            values_v_tide = ma.array(var_in_Vtide).flatten()[inds_reg]
            values_u_smoc = ma.array(var_in_Usmoc).flatten()[inds_reg]
            values_v_smoc = ma.array(var_in_Vsmoc).flatten()[inds_reg]
        SMOC.close()
    else:
        log.info(f"Missing file SMOC for date {datevalue}")
        sys.exit(1)

    return value_uclim0, value_vclim0, values_u_stokes, values_v_stokes,\
        values_u_tide, values_v_tide, values_u_smoc, values_v_smoc


def select_drifters(log, params_dict, YEAR, MONTH, ts, depthvalue=15.0):
    TYPE = params_dict['TYPE']
    SUFFIX = params_dict['SUFFIX']
    ZONE = params_dict['ZONE']
    DIRDATA = params_dict['DIRDATA']
    if TYPE == "013_030":
        frame = ZONE + '_' + str(YEAR) + str(MONTH) + '_' + SUFFIX + '*.nc'
    elif TYPE == "013_048":
        frame = ZONE + '_' + SUFFIX + '*' + str(YEAR) + str(MONTH)+'.nc'
    nb_files = len(glob(DIRDATA + str(YEAR) + str(MONTH) + '/' + frame))
    log.debug(f'Number of files {nb_files}')
    list_file = []
    list_lon = []
    list_lat = []
    list_drift = []
    list_time = []
    list_u15 = []
    list_v15 = []
    list_depth = []
    list_depth0 = []
    list_depthqc0 = []
    list_depthqc = []
    list_windu = []
    list_windv = []
    list_u0 = []
    list_v0 = []
    list_uqc = []
    list_vqc = []
    list_time = []
    list_time_ref = []
    list_current_test0 = []
    list_current_test15 = []
    list_current_test_qc15 = []
    list_current_test_qc0 = []
    list_position_qc = []
    list_time_qc = []
    list_dc_reference = []
    for f, file in enumerate(glob(params_dict['DIRDATA'] + str(YEAR) +
                             str(MONTH) + '/' + frame)):
        list_file.append(file)
        if params_dict['TYPE'] == "013_030":
            drifter = os.path.basename(file).\
                    split('_')[4].split('.')[0]
        elif params_dict['TYPE'] == "013_048":
            drifter = os.path.basename(file).\
                    split('_')[3].split('.')[0]
        # list_drifters.append(drifter)
        # ind_dict[drifter] = {}
        try:
            lon_value, lat_value, depth, depth_qc, time, u_ewct, v_nsct,\
                    ll_var, u_qc, v_qc, wind_u, wind_v, current_test, \
                    current_test_qc, position_qc, time_qc, dc_reference = \
                    read_drifter(file)
        except cl4err:
            raise cl4err.Class4FatalError(f"Pb with drifter file {file}")
        date_val = pd.to_datetime(time).strftime('%Y-%m-%d')
        w_depth15 = np.where(np.array(depth) == depthvalue)
        ndim1, ndim2 = np.shape(depth)
        vtime = time.astype('M8[ms]').astype('O')
        vect_time = []
        if len(w_depth15[0]) > 0:
            ind_x15 = w_depth15[0]
            ind_y15 = w_depth15[1]
            u_ewct15 = np.array(u_ewct)[ind_x15, ind_y15]
            v_nsct15 = np.array(v_nsct)[ind_x15, ind_y15]
            lon_15 = np.array(lon_value)[ind_x15]
            lat_15 = np.array(lat_value)[ind_x15]
            u_ewct0 = np.array(u_ewct)[ind_x15, 0]
            v_nsct0 = np.array(v_nsct)[ind_x15, 0]
            depth0 = np.array(depth)[ind_x15, 0]
            depth15 = np.array(depth)[ind_x15, 1]
            u_qc0 = np.array(u_qc)[ind_x15, 0]
            v_qc0 = np.array(v_qc)[ind_x15, 0]
            time_qc_tmp = time_qc[ind_x15]
            depth0 = np.array(depth)[ind_x15, 0]
            depth_qc0 = np.array(depth_qc)[ind_x15, 0]
            current_test_qc0 = np.array(current_test_qc)[ind_x15, 0]
            current_test0 = np.array(current_test)[ind_x15, 0]
            position_qc_tmp = position_qc[ind_x15]
            dc_reference_tmp = dc_reference[ind_x15]
            for t in range(len((w_depth15[0]))):
                vect_time.append(vtime[t].strftime('%Y%m%d%H'))
            ndays = len(vect_time)
            vector_time = np.nan*np.zeros((ndays))
            for il_ind, daytime in enumerate(np.array(vect_time)):
                vector_time[il_ind] = (dt.datetime.strptime(daytime, '%Y%m%d%H').
                                       toordinal()-dateCNESref)*24+int(daytime[8:10])
            time_15 = np.array(date_val)[ind_x15]
            u_qc15 = np.array(u_qc)[ind_x15, ind_y15]
            v_qc15 = np.array(v_qc)[ind_x15, ind_y15]
            depth15 = np.array(depth)[ind_x15, ind_y15]
            depth_qc15 = np.array(depth_qc)[ind_x15, ind_y15]
            current_test_qc15 = np.array(current_test_qc)[ind_x15, ind_y15]
            current_test15 = np.array(current_test)[ind_x15, ind_y15]
            if len(np.shape(wind_u)) > 0 and len(np.shape(wind_v)) > 0:
                u_wind = np.array(wind_u)[:, 0]
                v_wind = np.array(wind_v)[:, 0]
            else:
                print(f"Missing_wind {file}")
                nb_times, nb_depths = np.shape(u_ewct)
                u_wind = np.nan*np.zeros(nb_times)
                v_wind = np.nan*np.zeros(nb_times)
            if len(w_depth15[0]) != ndim1:
                log.error(f"Missing some depth at 15m depth {file}")
            ll_var15 = True
        else:
            ll_var15 = False
            log.error(f'Missing depth 15m {file=}')
        list_lon.extend(lon_15)
        list_lat.extend(lat_15)
        list_time_ref.extend(time_15)
        list_time.extend(vector_time.tolist())
        list_depth.extend(depth15)
        list_depth0.extend(depth0)
        list_u15.extend(u_ewct15)
        list_v15.extend(v_nsct15)
        list_windu.extend(u_wind)
        list_windv.extend(v_wind)
        list_u0.extend(u_ewct0)
        list_v0.extend(v_nsct0)
        list_uqc.extend(u_qc15)
        list_vqc.extend(v_qc15)
        list_depthqc0.extend(depth_qc0)
        list_depthqc.extend(depth_qc15)
        list_current_test0.extend(current_test0)
        list_current_test15.extend(current_test15)
        list_current_test_qc15.extend(current_test_qc15)
        list_current_test_qc0.extend(current_test_qc0)
        list_position_qc.extend(position_qc_tmp)
        list_time_qc.extend(time_qc_tmp)
        list_dc_reference.extend(dc_reference_tmp)
        for i in range(len(lon_15)):
            list_drift.append(str(drifter))
        #log.debug(f"Read drifter OK {f} / {nb_files}")
        #print(f"drifter={list_drift}")
    if not list_lon:
        raise BaseException('Missing input UV drifters')
    log.debug("Read all drifters OK")
    tab_value = {}
    for day in ts:
        log.debug(f"Dayvalue {day=}")
        tab_value[str(day)] = {}
        ind = np.where(np.array(list_time_ref) == str(day))
        tab_value[str(day)]['time'] = np.array(list_time)[ind]
        tab_value[str(day)]['lon'] = np.array(list_lon)[ind]
        tab_value[str(day)]['lat'] = np.array(list_lat)[ind]
        tab_value[str(day)]['depth'] = np.array(list_depth)[ind]
        tab_value[str(day)]['depth0'] = np.array(list_depth0)[ind]
        tab_value[str(day)]['u'] = np.array(list_u15)[ind]
        tab_value[str(day)]['v'] = np.array(list_v15)[ind]
        tab_value[str(day)]['windu'] = np.array(list_windu)[ind]
        tab_value[str(day)]['windv'] = np.array(list_windv)[ind]
        tab_value[str(day)]['u0'] = np.array(list_u0)[ind]
        tab_value[str(day)]['v0'] = np.array(list_v0)[ind]
        tab_value[str(day)]['uqc'] = np.array(list_uqc)[ind]
        tab_value[str(day)]['vqc'] = np.array(list_vqc)[ind]
        tab_value[str(day)]['depth_qc0'] = np.array(list_depthqc0)[ind]
        tab_value[str(day)]['depth_qc'] = np.array(list_depthqc)[ind]
        tab_value[str(day)]['current_test0'] = np.array(list_current_test0)[ind]
        tab_value[str(day)]['current_test15'] = np.array(list_current_test15)[ind]
        tab_value[str(day)]['current_test_qc15'] = np.array(list_current_test_qc15)[ind]
        tab_value[str(day)]['current_test_qc0'] = np.array(list_current_test_qc0)[ind]
        tab_value[str(day)]['position_qc'] = np.array(list_position_qc)[ind]
        tab_value[str(day)]['time_qc'] = np.array(list_time_qc)[ind]
        tab_value[str(day)]['dc_reference'] = np.array(list_dc_reference)[ind]
        tab_value[str(day)]['id_drift'] = np.array(list_drift)[ind]
        log.debug(f"Position {tab_value[str(day)]['lon']}")

    return tab_value, nb_files


def interpolate_drifters(log, params_dict, lon1, lat1,
                         lon2, lat2, year, month, name):
    nb_ptsinterp = int(params_dict['nb_ptsinterp'])
    DIR_INTERP = params_dict['DIR_INTERP']
    weight_file = DIR_INTERP + name + '_' + str(nb_ptsinterp) +\
        'pts_drifters_' + str(year) + "_" +\
        str(month) + ".nc"
    start = timer()
    save = False
    TreeObj = interp_KDtree(log)
    try:
        log.debug(f'Interpolate {np.shape(lon1)}\
                   on {np.shape(lon2)}')
        dist, inds = TreeObj.tree_and_query(lon1, lat1,
                                           lon2, lat2,
                                           nb_ptsinterp,
                                           weight_file=weight_file,
                                           save=save)
        log.debug('Interpolate on irregular grid ok')
    except Exception:
        raise
    end = timer()
    log.debug(f'~~~ Time elapsed coloc: {end-start} ~~~')
    weight = TreeObj.get_weight(dist)

   # return dist, idw
    return weight, inds


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                       INPUT PARAMETERS SETTINGS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
letters = 'y:m'
loglevel = 2
keywords = ['year=', 'month=', 'system=', 'debug']
cla_opts = getopt.getopt(sys.argv[1:], letters, keywords)

for o, p in cla_opts[0]:
    if o in ['-y', '--year']:
        year = int(p)
    elif o in ['-m', '--month']:
        month = int(p)
    elif o in ['-s', '--system']:
        system = str(p)
    elif o in ['--debug']:
        loglevel = 1

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Define the time period ~~~~~~~~~~~~~~~~~~~
if month < 10:
    month2 = '0'+str(month)
else:
    month2 = str(month)
day = compute_last_day_month(year, month)
dt_start = dt.date(year, month, 1)
dt_end = dt.date(year, month, day)
ndays = (dt_end - dt_start).days + 1
ts = np.array([dt_start + dt.timedelta(i) for i in range(ndays)])
dateval = pd.to_datetime(ts).strftime('%Y%m%d')
# Number of components U&V
nb_comp = 2
# Number of depths
nb_profs = 2
# ~~~~~~~~~~~~~~~~~~~~~~~~ Define configuration (path, date, etc.) ~~~~~~~~

log = Logger('TEP_CLASS2').run(loglevel)
dateCNESref = dt.datetime.strptime('1950010100', '%Y%m%d%H').toordinal()
log.debug(f"Launch interpolation for {year} {month2}")

# ~~~~~~~~~~~~~~~~~~~~ Read Config file ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
deb_file = '../cfg/config_'+system+'_UV.cfg'
params_dict = load_param(deb_file)
DIRDATA = params_dict['DIRDATA']
ZONE = params_dict['ZONE']
TYPE = params_dict['TYPE']
SUFFIX = params_dict['SUFFIX']
nb_fcst = int(params_dict['nb_fcst'])
nb_pers = int(params_dict['nb_pers'])
nb_ptsinterp = int(params_dict['nb_ptsinterp'])
path_data = params_dict['path_data']

comm = MPI.COMM_WORLD
for num_proc in range(comm.size):
    if comm.rank == num_proc:
        # List available drifter and create dictionnary
        log.debug("Read drifter coordinates and interpolate")
        tab_value, nb_files = select_drifters(log, params_dict, year, month2, ts)
        # Read Grid files
        try:
            lon_mod, lat_mod = read_pos(params_dict['coordinates'], log)
            mod_coord = xr.open_dataset(params_dict['coordinates'])
            log.debug(f"Read ok {params_dict['coordinates']}")
        except IOError:
            log.error("Open Error coordinates")
            sys.exit(1)
        try:
            lon_mod_reg, lat_mod_reg = \
                    read_pos_reg(params_dict['coordinates_reg'])
            log.debug("Read ok reg")
            log.debug(f"{params_dict['coordinates_reg']}")
            log.debug(f"{np.shape(lon_mod_reg)}")
        except IOError:
            log.error("Open Error coordinates_reg")
            sys.exit(1)
        try:
            lon_clim, lat_clim = \
                    read_pos_clim(params_dict['coordinates_clim'])
            log.debug("Read ok clim")
        except IOError:
            log.error("Open Error climatology")

comm.Barrier()

comm = MPI.COMM_WORLD
log.info(f'{comm.size=}')
log.info(f'{comm.rank=}')
if comm.size > 1:
    ndays = len(ts)
    log.info(f"Nb days {ndays}")
    irest = np.mod(ndays, comm.size)
    ntask = round(ndays / comm.size)
    log.info(f"Nb tasks {ntask}")
    istart = ntask*comm.rank
    iend = istart + ntask - 1
    cla_df = ts[istart:iend+1]
    iend_tot = ntask*comm.size-1
    log.info(f"istart {istart} iend {iend}")
    log.info(f"cla_df {cla_df}")

for i, day in enumerate(cla_df):
    datevalue = day.strftime('%Y%m%d')
    # Interpolate
    # ~~~~(cla_df~ Interpolate drifters positions on orca grid ~~~~~~~~~
    log.debug(f'Interpolate on orca grid {day=}')
    name = 'weight_file_orca_' + str(nb_files)
    weight, inds = interpolate_drifters(log, params_dict,
                                     lon_mod, lat_mod,
                                     tab_value[str(day)]['lon'],
                                     tab_value[str(day)]['lat'],
                                     year, month, name)
    # ~~~~~~~~ Interpolate drifters positions on regular grid ~~~~~~~~~
    log.debug(f'Interpolate on regular grid {day=}')
    name = 'weight_file_regular_' + str(nb_files)
    weight_reg, inds_reg = interpolate_drifters(log, params_dict,
                                             lon_mod_reg, lat_mod_reg,
                                             tab_value[str(day)]['lon'],
                                             tab_value[str(day)]['lat'],
                                             year, month, name)
    # ~~~~~~~~ Interpolate drifters positions on clim regular grid ~~~~~~~~
    log.debug(f'Interpolate on regular grid clim {day=}')
    name = 'weight_file_clim_' + str(nb_files)
    weight_clim, inds_clim = interpolate_drifters(log, params_dict,
                                               lon_clim, lat_clim,
                                               tab_value[str(day)]['lon'],
                                               tab_value[str(day)]['lat'],
                                               year, month, name)

    log.debug(f'Process Coloc terminated {np.shape(inds_clim)} {day=}')
    nbobs = np.shape(tab_value[str(day)]['lon'])[0]
    # Initialize arrays
    DATA_SAVE_obs = np.nan*np.zeros((nbobs, nb_comp, nb_profs))
    DATA_SAVE_best = np.nan*np.zeros((nbobs, nb_comp, nb_profs))
    DATA_SAVE_clim = np.nan*np.zeros((nbobs, nb_comp, nb_profs))
    DATA_SAVE_stokes = np.nan*np.zeros((nbobs, nb_comp))
    DATA_SAVE_tides = np.nan*np.zeros((nbobs, nb_comp))
    DATA_SAVE_smoc = np.nan*np.zeros((nbobs, nb_comp))
    DATA_SAVE_fcst = np.nan*np.zeros((nbobs, nb_comp, nb_fcst,
                                  nb_profs))
    DATA_SAVE_pers = np.nan*np.zeros((nbobs, nb_comp, nb_fcst,
                                         nb_profs))
    DATA_SAVE_obs[:, 0, 0] = np.array(tab_value[str(day)]['u0'])
    DATA_SAVE_obs[:, 1, 0] = np.array(tab_value[str(day)]['v0'])
    DATA_SAVE_obs[:, 0, 1] = np.array(tab_value[str(day)]['u'])
    DATA_SAVE_obs[:, 1, 1] = np.array(tab_value[str(day)]['v'])

    for ech in range(nb_fcst + nb_pers + 1):
        start = timer()
        #ilon = [int(ilon[i]) for i, val in enumerate(ilon)]
        #ilat = [int(ilat[i]) for i, val in enumerate(ilat)]
        values_u15_interp, values_v15_interp, values_u0, values_v0 = \
                            read_mod_and_interp(log, ech, nb_fcst, params_dict,
                                                weight,
                                                inds,
                                                datevalue,
                                                nb_ptsinterp)
        ### Populate arrays
        if ech == 0:
            #log.debug("Leadtime Hindcast")
            DATA_SAVE_best[:, 0, 0] = values_u0
            DATA_SAVE_best[:, 1, 0] = values_v0
            DATA_SAVE_best[:, 0, 1] = values_u15_interp
            DATA_SAVE_best[:, 1, 1] = values_v15_interp
        elif ech > 0  and ech <= nb_fcst:
            #log.debug("Leadtime Forecast")
            indf = ech-1
            DATA_SAVE_fcst[:, 0, indf, 0] = values_u0
            DATA_SAVE_fcst[:, 1, indf, 0] = values_v0
            DATA_SAVE_fcst[:, 0, indf, 1] = values_u15_interp
            DATA_SAVE_fcst[:, 1, indf, 1] = values_v15_interp
        elif ech > nb_fcst:
            #log.debug("Leadtime Persistence")
            indp = ech-nb_fcst-1
            DATA_SAVE_pers[:, 0, indp, 0] = values_u0
            DATA_SAVE_pers[:, 1, indp, 0] = values_v0
            DATA_SAVE_pers[:, 0, indp, 1] = values_u15_interp
            DATA_SAVE_pers[:, 1, indp, 1] = values_v15_interp
        end = timer()
        log.debug(f'~~~~~~~~ Loop time  : {end - start} {ech=} {day=} ~~~~~~~~')

    value_uclim0, value_vclim0, values_u_stokes, values_vstokes,\
            values_utide, values_vtide, values_usmoc, values_vsmoc = \
                read_smoc_and_clim(params_dict,
                                   weight_clim,
                                   inds_clim,
                                   weight_reg,
                                   inds_reg,
                                   datevalue,
                                   nb_ptsinterp)
    DATA_SAVE_clim[:, 0, 0] = value_uclim0[:]
    DATA_SAVE_clim[:, 1, 0] = value_vclim0[:]
    DATA_SAVE_clim[:, 0, 1] = value_uclim0[:]
    DATA_SAVE_clim[:, 1, 1] = value_vclim0[:]
    DATA_SAVE_stokes[:, 0] = values_u_stokes
    DATA_SAVE_stokes[:, 1] = values_vstokes
    DATA_SAVE_tides[:, 0] = values_utide
    DATA_SAVE_tides[:, 1] = values_vtide
    DATA_SAVE_smoc[:, 0] = values_usmoc
    DATA_SAVE_smoc[:, 1] = values_vsmoc
    nb_profs = 2
    nb_days = len(tab_value[str(day)]['depth'])
    depth_tmp = np.nan*np.zeros((nb_days, nb_profs))
    depth_qc_tmp = np.nan*np.zeros((nb_days, nb_profs))
    current_test_qc_tmp = np.nan*np.zeros((nb_days, nb_profs))
    current_test_tmp = np.nan*np.zeros((nb_days, nb_profs))
    depth_tmp[:, 0] = np.array(tab_value[str(day)]['depth0'])
    depth_tmp[:, 1] = np.array(tab_value[str(day)]['depth'])
    depth_qc_tmp[:, 0] = np.array(tab_value[str(day)]['depth_qc0'])
    depth_qc_tmp[:, 1] = np.array(tab_value[str(day)]['depth_qc'])
    current_test_qc_tmp[:, 0] = np.array(tab_value[str(day)]['current_test_qc0'])
    current_test_qc_tmp[:, 1] = np.array(tab_value[str(day)]['current_test_qc15'])
    current_test_tmp[:, 0] = np.array(tab_value[str(day)]['current_test0'])
    current_test_tmp[:, 1] = np.array(tab_value[str(day)]['current_test15'])

    end = timer()
    log.debug(f'~~~~~~~~ Time Smoc and clim : {end - start} {day=} ~~~~~~~')
    start = timer()
    nc_file_out = path_data + 'class4_' + datevalue + '_' +\
            system + '_orca12_currents.nc'
    log.debug(f'~~~~~~~~ Write nc file : {datevalue} {nc_file_out} ~~~~~~~')
    write_cl4_files(nc_file_out, tab_value[str(day)]['lat'],
                    tab_value[str(day)]['lon'], tab_value[str(day)]['id_drift'],
                    DATA_SAVE_obs, np.asarray(DATA_SAVE_best),
                    np.asarray(DATA_SAVE_fcst), np.asarray(DATA_SAVE_pers),
                    np.asarray(DATA_SAVE_stokes), np.asarray(DATA_SAVE_tides),
                    np.asarray(DATA_SAVE_smoc), tab_value[str(day)]['time'],
                    tab_value[str(day)]['uqc'], tab_value[str(day)]['vqc'],
                    depth_tmp, depth_qc_tmp, current_test_tmp, current_test_qc_tmp,
                    tab_value[str(day)]['position_qc'],  tab_value[str(day)]['time_qc'],
                    tab_value[str(day)]['dc_reference'], tab_value[str(day)]['windu'],
                    tab_value[str(day)]['windv'], np.asarray(DATA_SAVE_clim), nb_fcst,
                    system, TYPE)

comm.Barrier()
log.info(f'Process terminated rank {comm.rank} {day=}')

    # print ('*********************************')
# comm.Barrier()
