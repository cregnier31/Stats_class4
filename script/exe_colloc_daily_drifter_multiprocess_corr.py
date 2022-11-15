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
import vertical
import cl4errors as cl4err
import pandas as pd
import xarray as xr
from timeit import default_timer as timer
from utils import compute_last_day_month, find_index_month
from loader_post import load_param
from writer import write_cl4_files
from mpi4py import MPI
import numpy.ma as ma
from interpolate import interpolate_drifters
from reader_interp import read_mod_and_interp, read_smoc_clim_interp
import datetime

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
            #mod_coord = xr.open_dataset(params_dict['coordinates'])
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
        try:
            mod_hgr = xr.open_dataset(params_dict['coordinates_hgr'])
            gsinU = mod_hgr['gsinu']
            gcosU = mod_hgr['gcosu']
            gsinV = mod_hgr['gsinv']
            gcosV = mod_hgr['gcosv']
            gsinT = mod_hgr['gsint']
            gcosT = mod_hgr['gcost']
            log.debug(f"Read ok")
        except IOError:
            log.error("Open Error coordinates_hgr")

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

##cla_df = ts
#d = datetime.date(2022,9,17)
#cla_df=[]
#cla_df.append(d)
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
    if nb_ptsinterp == 1:
        log.debug('Read gsin gcos')
        gsinU_interp = ma.array(gsinU).flatten()[inds]
        gsinV_interp = ma.array(gsinV).flatten()[inds]
        gcosU_interp = ma.array(gcosU).flatten()[inds]
        gcosV_interp = ma.array(gcosV).flatten()[inds]
        gsint_interp = ma.array(gsinT).flatten()[inds]
        gcost_interp = ma.array(gcosT).flatten()[inds]
    else:
        print("not implemented yet")
        sys.exit(1)

    nbobs = np.shape(tab_value[str(day)]['lon'])[0]
    # Initialize arrays
    DATA_SAVE_obs = np.nan*np.zeros((nbobs, nb_comp, nb_profs))
    DATA_SAVE_best = np.nan*np.zeros((nbobs, nb_comp, nb_profs))
    log.debug(f"Size DATA_SAVE_best {np.shape(DATA_SAVE_best)}")
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
        values_u15_interp, values_v15_interp, values_u0, values_v0 = \
                            read_mod_and_interp(log, ech, nb_fcst, params_dict,
                                                weight,
                                                inds,
                                                datevalue,
                                                nb_ptsinterp)
        log.debug(f"Size uo {np.shape(values_u0)}")
        # Corrected values
        ucorr0 = values_u0*gcost_interp - values_v0*gsint_interp
        log.debug(f"Size corr uo {np.shape(ucorr0)}")
        vcorr0 = values_u0*gsint_interp + values_v0*gcost_interp
        ucorr15 = values_u15_interp*gcost_interp - values_v15_interp*gsint_interp
        vcorr15 = values_u15_interp*gsint_interp + values_v15_interp*gcost_interp
        #print(f'Difference en U :{values_u0-ucorr0} {day} {ech}')
        #print(f'Difference en V {values_u0-vcorr0}')
        #sys.exit(1)
        # Populate arrays
        if ech == 0:
            log.debug(f"Leadtime Hindcast {np.shape(ucorr0)}")
            log.debug(f"Shape DATA_SAVE_best {np.shape(DATA_SAVE_best)}")
            DATA_SAVE_best[:, 0, 0] = ucorr0
            DATA_SAVE_best[:, 1, 0] = vcorr0
            DATA_SAVE_best[:, 0, 1] = ucorr15
            DATA_SAVE_best[:, 1, 1] = vcorr15
        elif ech > 0  and ech <= nb_fcst:
            log.debug("Leadtime Forecast")
            indf = ech-1
            DATA_SAVE_fcst[:, 0, indf, 0] = ucorr0
            DATA_SAVE_fcst[:, 1, indf, 0] = vcorr0
            DATA_SAVE_fcst[:, 0, indf, 1] = ucorr15
            DATA_SAVE_fcst[:, 1, indf, 1] = vcorr15
        elif ech > nb_fcst:
            log.debug("Leadtime Persistence")
            indp = ech-nb_fcst-1
            DATA_SAVE_pers[:, 0, indp, 0] = ucorr0
            DATA_SAVE_pers[:, 1, indp, 0] = vcorr0
            DATA_SAVE_pers[:, 0, indp, 1] = ucorr15
            DATA_SAVE_pers[:, 1, indp, 1] = vcorr15
        end = timer()
        log.debug(f'~~~~~~~~ Loop time  : {end - start} {ech=} {day=} ~~~~~~~~')

    value_uclim0, value_vclim0, values_u_stokes, values_vstokes,\
            values_utide, values_vtide, values_usmoc, values_vsmoc = \
                read_smoc_clim_interp(log,
                                      params_dict,
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
