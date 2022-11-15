import sys
import numpy as np
import numpy.ma as ma
import netCDF4
from netCDF4 import Dataset
import utilities
import xarray as xr
import dask
from glob import glob
from Interpolator import Interpolator
from utils import find_index_month

__version__ = 0.1
__date__ = "February 2019"
__authors__ = "C.REGNIER & C.SZCZYPTA"

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
        log.error("Files are missing in U and V")
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
            log.error(f"Pb with file {file_mod_U}")
            log.error(f"Pb with file {file_mod_V}")
            raise Exception
    return tab_interp_U, tab_interp_V, tab_interp_U0, tab_interp_V0


def read_smoc_clim_interp(log,
                          params_dict,
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
        raise(log.error(f"Missing file SMOC for date {datevalue}"))
        sys.exit(1)

    return value_uclim0, value_vclim0, values_u_stokes, values_v_stokes,\
        values_u_tide, values_v_tide, values_u_smoc, values_v_smoc
