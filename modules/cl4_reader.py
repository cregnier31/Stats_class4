import numpy as np
import netCDF4
import supobs
import param.Def_param_bulletin as params
import utils
## Cpu utility
import psutil
import time
from timeit import default_timer as timer
import sys

__version__ = 0.1
__date__ = "February 2019"
__authors__ = "C.SZCZYPTA & C.REGNIER"

def cfg_ltime(cl_file, cexp, cvar):
    """
        Function to read all the lead times contained
        in a class4 file
    """

    lead_time = []
    yout = 0
    missing_value = 1e35
    nb_fcst = None

    nc   = netCDF4.Dataset(cl_file, 'r')
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
    rla_forecast[:] = missing_value
    num_col = 0
    if 'best_estimate' in lead_time :
        rla_forecast[num_col] = 0.
        num_col += 1
    if 'forecast' in lead_time and cexp == 'BIO':
        rla_forecast[num_col] = 336.
        num_col += 1
    if 'forecast' in lead_time and cexp == 'PHYS' and nb_fcst != None:
        for f in range(nb_fcst//2+1):
            rla_forecast[num_col] = (f*48.)+12.
            num_col += 1
    if 'persistence' in lead_time and cexp == 'BIO':
        rla_forecast[num_col] = -336.
        num_col += 1
    if 'persistence' in lead_time and cexp == 'PHYS' and nb_fcst != None:
        for f in range(nb_fcst//2+1):
            rla_forecast[num_col] = -(f*48.)-12.
            num_col += 1
    if 'climatology' in lead_time:
        rla_forecast[num_col] = 1.
    dict_inputs = {}
    dict_inputs['lead_time'] = lead_time
    dict_inputs['yout'] = yout
    dict_inputs['rla_forecast'] = rla_forecast
    dict_inputs['nb_fcst'] = nb_fcst
    dict_inputs['missing_value'] = missing_value

    return dict_inputs



def read_inputfile(cvar, cexp, ncfile, params_conf, log):
    """
        Read input netcdf file with all lead times

        Arguments
        --------------------
        lead_time: input lead time
        cvar: input variable name
        cexp: input type BIO or PHYS
        ncfile: input netcdf file
        Returns
        --------------------
        dict_inputs: dictionnary with all inputs arrays
        for observations, model values and climatology
    """
    #*************  Initialisation *******************

    rla_observation_var = np.nan
    rla_best_estimate_var = np.nan
    rla_persistence_var = np.nan
    rla_forecast_var = np.nan
    rla_climatology_var = np.nan
    rg_EcartMax = params.rg_EcartMax
    bad_qc = params.bad_qc
    dict_inputs = cfg_ltime(ncfile, cexp, cvar)
    lead_time = dict_inputs['lead_time']
    yout = dict_inputs['yout']
    rla_forecast = dict_inputs['rla_forecast']
    nb_fcst = dict_inputs['nb_fcst']
    missing_value = dict_inputs['missing_value']

    # *********************  Read observation positions  *********************

    if cexp == 'BIO':
        rla_lonobs,rla_latobs, rla_depthobs = \
        supobs.toolkitStats.read_CL4obs_chloro(ncfile)
    else:
        cla_varname,rla_lonobs,rla_latobs,rla_depthobs = \
        supobs.toolkitStats.read_CL4obs(ncfile)
        varname_psal = 0 ; varname_temp = 0
        varname_u = 0 ; varname_v = 0

        if 'vosaline' in cla_varname: varname_psal = 'vosaline'
        if 'salt    ' in cla_varname: varname_psal = 'salt    '
        if 'votemper' in cla_varname: varname_temp = 'votemper'
        if 'temp    ' in cla_varname: varname_temp = 'temp    '
        if 'eastward_velocity' in cla_varname : varname_u = 'eastward_velocity'
        if 'northward_velocity' in cla_varname: varname_v = 'northward_velocity'

    if cvar == 'PSAL' and varname_psal == 0:
        log.info("Pb with file %s : " %(str(ncfile)))
        log.info("Error: varname_psal not defined")
        sys.exit(1)
    if cvar == 'TEMP' and varname_temp == 0:
        log.info("Pb with file %s : " %(str(ncfile)))
        log.info("Error: varname_temp not defined")
        sys.exit(1)
    if cvar == 'UVEL' and varname_u == 0:
        log.info("Pb with file %s : " %(str(ncfile)))
        log.info("Error: varname_u not defined")
        sys.exit(1)
    if cvar == 'VVEL' and varname_v == 0:
        log.info("Pb with file %s : " %(str(ncfile)))
        log.info("Error: varname_v not defined")
        sys.exit(1)

    if rla_depthobs.shape[1] == 1 and (rla_depthobs[:,0] == 0).all():
        tab_prof   = np.array([-0.5,0.5])
    elif cvar == 'UVEL' or cvar == 'VVEL' :
        tab_prof   = np.array([-0.5,0.5])
        rla_depthobs = np.expand_dims(rla_depthobs[:,1], axis=1)
    elif params_conf['percent'] == 'on':
        tab_prof = params.tab_prof_model
    else:
        rla_layers = params_conf['layers']
        tab_prof = np.array(rla_layers)

    # ******************  Read observation and model simulation values  ******************

    nc = netCDF4.Dataset(ncfile, 'r')
    ll_ice = False
    ll_currents = False
    ll_best = False
    ll_fcst = False
    ll_pers = False
    ll_clim = False
    for time in lead_time:
        if time == 'observation' and cexp == 'BIO': run_name = cvar.upper()
        else: run_name = time
        if time == 'forecast':
            rla_forecast_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,ncfile)
            ll_fcst = True
        if time == 'persistence':
            rla_persistence_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,ncfile)
            ll_pers = True
        if time == 'observation':
            rla_observation_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,ncfile)
        if time == 'best_estimate':
            rla_best_estimate_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,ncfile)
            ll_best = True
        if time == 'climatology':
            rla_climatology_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,ncfile)
            ll_clim = True
        if cexp == 'PHYS':
            if cvar in ['SST', 'SLA', 'PSAL', 'TEMP']:
                cl_qcvar = 'qc'
            elif cvar ==  'aice':
                ll_ice = True
                cl_qcvar = 'QC02'
                cl_qcvar2 = 'QC07'
                rla_qc_init2 = nc.variables[cl_qcvar2][:]
            elif cvar in ['VVEL', 'UVEL']:
                ll_currents = True
                cl_qcvar = 'current_test_qc'
                cl_qcvar2 = 'position_qc'
                cl_qcvar3 = 'obs_qc'
                cl_qcvar4 = 'current_test'
                rla_qc_init2 = nc.variables[cl_qcvar2][:]
                rla_qc_init3 = nc.variables[cl_qcvar3][:]
                rla_qc_init4 = nc.variables[cl_qcvar4][:]
            else:
                cl_qcvar = 'qc'
            rla_qc_init = nc.variables[cl_qcvar][:]

    nc.close()
    if not ll_fcst: print ("Forecast is missing for %s " %(ncfile))
    if not ll_pers: print ("Persistence is missing for %s " %(ncfile))
    if not ll_best: print ("Best estimate is missing for %s " %(ncfile))
    if not ll_best and not ll_fcst and  not ll_pers : return None

    if cexp == 'BIO':
        if 'observation' in lead_time: rla_observation_var = np.reshape(rla_observation_init,rla_lonobs.size)
        if 'forecast' in lead_time: rla_forecast_var = np.reshape(rla_forecast_init,rla_lonobs.size)
        if 'best_estimate' in lead_time: rla_best_estimate_var = np.reshape(rla_best_estimate_init,rla_lonobs.size)
        if 'climatology' in lead_time: rla_climatology_var = np.reshape(rla_climatology_init,rla_lonobs.size)
        if 'persistence' in lead_time: rla_persistence_var = np.reshape(rla_persistence_init,rla_lonobs.size)
    elif cexp == 'PHYS':
        if cvar in ['SST','SLA','aice']: ivar = 0
        elif cvar == 'PSAL': ivar = np.where(np.array(cla_varname) == varname_psal)[0][0]
        elif cvar == 'TEMP': ivar = np.where(np.array(cla_varname) == varname_temp)[0][0]
        elif cvar == 'UVEL': ivar = np.where(np.array(cla_varname) == varname_u)[0][0]
        elif cvar == 'VVEL': ivar = np.where(np.array(cla_varname) == varname_v)[0][0]
        if ll_currents:
            rla_qc_var = rla_qc_init[:,:]
            rla_qc_var2 = rla_qc_init2[:]
            rla_qc_var3 = rla_qc_init3[:,:]
            rla_qc_var4 = rla_qc_init4[:,:]
        else:
            rla_qc_var = rla_qc_init[:,ivar,:]
        if ll_ice : rla_qc_var2 = rla_qc_init2[:,ivar,:]
        if 'observation' in lead_time: rla_observation_var = rla_observation_init[:,ivar,:]
        if 'forecast' in lead_time: rla_forecast_var = rla_forecast_init[:,ivar,:,:]
        if 'persistence' in lead_time: rla_persistence_var = rla_persistence_init[:,ivar,:,:]
        if ll_best:
            if len(rla_best_estimate_init.shape) == 4 and 'best_estimate' in lead_time:
                rla_best_estimate_var = rla_best_estimate_init[:,ivar,0,:]
            elif len(rla_best_estimate_init.shape) == 3 and 'best_estimate' in lead_time:
                rla_best_estimate_var = rla_best_estimate_init[:,ivar,:]
        if 'climatology' in lead_time: rla_climatology_var = rla_climatology_init[:,ivar,:]


    # ***************  quality control ***************

        rla_diffclim2obs = np.absolute(rla_climatology_var-rla_observation_var)
        rla_diffbest2obs = np.absolute(rla_best_estimate_var-rla_observation_var)
        qcs = np.where(rla_diffbest2obs > rg_EcartMax[cvar])
        if len(qcs[0]) > 0: rla_observation_var[qcs] = np.nan
        if type(rla_climatology_var) != float:
            if rla_climatology_var.any():
                qcs_clim = np.where(rla_diffclim2obs > rg_EcartMax[cvar])
                if len(qcs_clim[0]) > 0: rla_observation_var[qcs_clim] = np.nan
        if ll_ice:
            qc_file= np.where((rla_qc_var == bad_qc[cvar]) & (rla_qc_var2 == bad_qc[cvar]))
        elif ll_currents:
            qc_file = np.where((rla_qc_init[:,1] != 1) | (rla_qc_init2 != 1) | (rla_qc_init3[:,1] != 1)
                               | (rla_qc_init4[:,1] < 311))
            percent = round((len(qc_file[0])*100)/len(rla_lonobs),2)
            log.debug("File {} Currents : Percentage of bad values {}{} ".format(ncfile,percent,'%'))
        else:
            qcvalues = bad_qc[cvar]
            if len(qcvalues) == 1:
                qc_file = np.where(rla_qc_var == int(qcvalues[0]))
            elif len(qcvalues) >= 2:
                qc_file = np.where(rla_qc_var >= int(qcvalues[0]))
            else:
                log.error("No qc values")
                sys.exit(1)

        if len(qc_file[0]) > 0:
            rla_observation_var[qc_file] = np.nan

        w = np.where(np.isnan(rla_observation_var))
        rla_best_estimate_var[w] = np.nan
        if type(rla_climatology_var) != float:
            if rla_climatology_var.any():
                rla_climatology_var[w] = np.nan

        if 'forecast' in lead_time:
            for il in range(rla_forecast_var.shape[1]):
                rla_forecast_tmp = rla_forecast_var[:,il,:]
                rla_forecast_tmp[w] = np.nan
                rla_forecast_var[:,il,:] = rla_forecast_tmp
                del rla_forecast_tmp
                if 'persistence' in lead_time:
                    rla_persistence_tmp = rla_persistence_var[:,il,:]
                    rla_persistence_tmp[w] = np.nan
                    rla_persistence_var[:,il,:] = rla_persistence_tmp
                    del rla_persistence_tmp

    dict_inputs = {}
    if cvar in ['VVEL', 'UVEL']:
        rla_observation_var = np.expand_dims(rla_observation_var[:,1], axis=1)
        rla_best_estimate_var = np.expand_dims(rla_best_estimate_var[:,1], axis=1)
        rla_climatology_var = np.expand_dims(rla_climatology_var[:,1], axis=1)
        rla_forecast_var = np.expand_dims(rla_forecast_var[:,:,1],axis=2)
        rla_persistence_var = np.expand_dims(rla_persistence_var[:,:,1], axis=2)
    dict_inputs['obs'] = rla_observation_var
    dict_inputs['best'] = rla_best_estimate_var
    dict_inputs['frcst'] = rla_forecast_var
    dict_inputs['pers'] = rla_persistence_var
    dict_inputs['clim'] = rla_climatology_var
    dict_inputs['tab_profs'] = tab_prof
    dict_inputs['lonobs'] = rla_lonobs
    dict_inputs['latobs'] = rla_latobs
    dict_inputs['rla_depthobs'] = rla_depthobs
    dict_inputs['nb_fcst'] = nb_fcst
    dict_inputs['yout'] = yout
    dict_inputs['lead_time'] = lead_time
    dict_inputs['rla_forecast'] = rla_forecast
    dict_inputs['missing_value'] = missing_value
    return dict_inputs


def update_leadtime(cl_file, cl_var):
    """
        Function to read all the varnames contained
        in a class4 file
    """
    lead_time = []
    nc   = netCDF4.Dataset(cl_file, 'r')
    if 'observation' in nc.variables or cl_var in nc.variables: lead_time.append('observation')
    if 'best_estimate' in nc.variables: lead_time.append('best_estimate')
    if 'forecast' in nc.variables: lead_time.append('forecast')
    if 'persistence' in nc.variables: lead_time.append('persistence')
    if 'climatology' in nc.variables: lead_time.append('climatology')
    nc.close()

    return lead_time


def read_and_store_inputfiles(lead_time, cvar, cexp, num_date, cl_cl4file,
                              dict_var, ll_arc, ll_ant, ll_shift, rla_latmask, log):
    """
        Read input netcdf file with all lead times
        and store it in a dictionnary

        Arguments
        --------------------
        lead_time: input lead time
        cvar: input variable name
        cexp: input type BIO or PHYS
        num_date:  date index
        ncfile: input netcdf file
        dict_var: dictionnary to store input arrays
        ll_arc: logical for arctic region
        ll_ant: logical for antarctic region
        ll_shift: logical for shifting longitude in 0-360
        rla_latmask: input mask array

        Returns
        --------------------
        dict_var: updated dictionnary which store input arrays
        for observations, model values and climatology
    """

    bad_qc = params.bad_qc
    rg_EcartMax = params.rg_EcartMax
    if ll_arc : min_lat = np.nanmin(rla_latmask)
    if ll_ant : min_lat = np.nanmax(rla_latmask)

    if cexp == 'BIO':
        rla_lonobs,rla_latobs, rla_depthobs = \
        supobs.toolkitStats.read_CL4obs_chloro(cl_cl4file)
    else:
        cla_varname,rla_lonobs,rla_latobs,rla_depthobs = \
        supobs.toolkitStats.read_CL4obs(cl_cl4file)
        varname_psal = 0 ; varname_temp = 0
        varname_u = 0 ; varname_v = 0
        if 'vosaline' in cla_varname: varname_psal = 'vosaline'
        if 'salt    ' in cla_varname: varname_psal = 'salt    '
        if 'votemper' in cla_varname: varname_temp = 'votemper'
        if 'temp    ' in cla_varname: varname_temp = 'temp    '
        if 'eastward_velocity' in cla_varname : varname_u = 'eastward_velocity'
        if 'northward_velocity' in cla_varname: varname_v = 'northward_velocity'
    if ll_arc:
        ind = np.where(rla_latobs > min_lat)[0]
        rla_latobs = rla_latobs[ind]
        rla_lonobs = rla_lonobs[ind]
    if ll_ant:
        ind = np.where(rla_latobs < min_lat)[0]
        rla_latobs = rla_latobs[ind]
        rla_lonobs = rla_lonobs[ind]
    meminfo = psutil.Process().memory_info().rss / 2**20
    log.debug("RSS memory information 1 : %s " %(str(meminfo)))

    if cvar == 'PSAL' and varname_psal == 0:
        log.error("Error: varname_psal not defined")
        sys.exit(1)
    if cvar == 'TEMP' and varname_temp == 0:
        log.error("Error: varname_temp not defined")
        sys.exit(1)
    if cvar == 'UVEL' and varname_u == 0:
        log.info("Pb with file %s : " %(str(ncfile)))
        log.info("Error: varname_u not defined")
        sys.exit(1)
    if cvar == 'VVEL' and varname_v == 0:
        log.info("Pb with file %s : " %(str(ncfile)))
        log.info("Error: varname_v not defined")
        sys.exit(1)

    dict_var[cvar]['depth_obs'][str(num_date)] = rla_depthobs

    # ~~~~~~~~ Create rla_lonobs_tmp array for 0/360 conversion ~~~~~~~~~~~
    rla_lonobs_tmp = rla_lonobs.copy()
    if ll_shift:
        rla_lonobs_tmp = np.where(rla_lonobs_tmp<0,\
                                  rla_lonobs_tmp+360,rla_lonobs_tmp)

    dict_var[cvar]['longitude'][str(num_date)] = rla_lonobs
    dict_var[cvar]['latitude'][str(num_date)] = rla_latobs

    # ******************  add observation and model simulation values  ******************

    start = timer()

    meminfo = psutil.Process().memory_info().rss / 2**20
    log.debug("RSS memory information 2 : %s " %(str(meminfo)))
    nc = netCDF4.Dataset(cl_cl4file,'r')
    lead_time = update_leadtime(cl_cl4file, cvar.upper())
    ll_ice = False
    ll_best = False
    ll_fcst = False
    ll_pers = False
    ll_clim = False
    ll_currents = False
    for time in lead_time:
        if time == 'observation' and cexp == 'BIO': run_name = cvar.upper()
        else: run_name = time
        if time == 'forecast':
            rla_forecast_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,cl_cl4file)
            ll_fcst = True
        if time == 'persistence':
            rla_persistence_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,cl_cl4file)
            ll_pers = True
        if time == 'observation':
            rla_observation_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,cl_cl4file)
        if time == 'best_estimate':
            ll_best = True
            rla_best_estimate_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,cl_cl4file)
        if time == 'climatology':
            rla_climatology_init = supobs.toolkitStats.read_CL4_all_values(nc,run_name,cvar,cl_cl4file)
            ll_clim = True
        if cexp == 'PHYS':
            if cvar in ['SST', 'SLA', 'PSAL', 'TEMP']:
                cl_qcvar = 'qc'
            elif cvar ==  'aice':
                ll_ice = True
                cl_qcvar = 'QC02'
                cl_qcvar2 = 'QC07'
                rla_qc_init2 = nc.variables[cl_qcvar2][:]
            elif cvar in ['VVEL', 'UVEL']:
                ll_currents = True
                cl_qcvar = 'current_test_qc'
                cl_qcvar2 = 'position_qc'
                cl_qcvar3 = 'obs_qc'
                cl_qcvar4 = 'current_test'
                rla_qc_init2 = nc.variables[cl_qcvar2][:]
                rla_qc_init3 = nc.variables[cl_qcvar3][:]
                rla_qc_init4 = nc.variables[cl_qcvar4][:]
            else:
                cl_qcvar = 'qc'
            rla_qc_init = nc.variables[cl_qcvar][:]
    nc.close()
    meminfo = psutil.Process().memory_info().rss / 2**20
    log.debug("RSS memory information : %s " %(str(meminfo)))


    # ***************  work on each considered variable (sst,sla,votemper,etc.) ***************

    if cexp == 'BIO':
        if 'observation' in lead_time: rla_observation_var = np.reshape(rla_observation_init,rla_lonobs.size)
        if 'forecast' in lead_time: rla_forecast_var = np.reshape(rla_forecast_init,rla_lonobs.size)
        if 'best_estimate' in lead_time: rla_best_estimate_var = np.reshape(rla_best_estimate_init,rla_lonobs.size)
        if 'climatology' in lead_time: rla_climatology_var = np.reshape(rla_climatology_init,rla_lonobs.size)
        if 'persistence' in lead_time: rla_persistence_var = np.reshape(rla_persistence_init,rla_lonobs.size)
    elif cexp == 'PHYS':
        if cvar in ['SST','SLA','aice']: ivar = 0
        elif cvar == 'PSAL': ivar = np.where(np.array(cla_varname) == varname_psal)[0][0]
        elif cvar == 'TEMP': ivar = np.where(np.array(cla_varname) == varname_temp)[0][0]
        elif cvar == 'UVEL': ivar = np.where(np.array(cla_varname) == varname_u)[0][0]
        elif cvar == 'VVEL': ivar = np.where(np.array(cla_varname) == varname_v)[0][0]
        if ll_currents:
            rla_qc_var = rla_qc_init[:,:]
            rla_qc_var2 = rla_qc_init2[:]
            rla_qc_var3 = rla_qc_init3[:,:]
            rla_qc_var4 = rla_qc_init4[:,:]
        else:
            rla_qc_var = rla_qc_init[:,ivar,:]
        if ll_ice: rla_qc_var2 = rla_qc_init2[:,ivar,:]
        if ll_arc or ll_ant: rla_qc_var = rla_qc_init[ind,ivar,:]
        if ll_arc or ll_ant: rla_qc_var2 = rla_qc_init2[ind,ivar,:]
        if 'observation' in lead_time:
            if ll_arc or ll_ant:
                rla_observation_var = rla_observation_init[ind,ivar,:]
            else:
                rla_observation_var = rla_observation_init[:,ivar,:]
        if 'forecast' in lead_time:
            if ll_arc or ll_ant:
                rla_forecast_var = rla_forecast_init[ind,ivar,:,:]
            else:
                rla_forecast_var = rla_forecast_init[:,ivar,:,:]
        if 'persistence' in lead_time:
            if ll_arc or ll_ant:
                rla_persistence_var = rla_persistence_init[ind,ivar,:,:]
            else:
                rla_persistence_var = rla_persistence_init[:,ivar,:,:]
        if 'best_estimate' in lead_time:
            if len(rla_best_estimate_init.shape) == 4:
                if ll_arc or ll_ant:
                    rla_best_estimate_var = rla_best_estimate_init[ind,ivar,0,:]
                else:
                    rla_best_estimate_var = rla_best_estimate_init[:,ivar,0,:]
            elif len(rla_best_estimate_init.shape) == 3:
                if ll_arc or ll_ant:
                    rla_best_estimate_var = rla_best_estimate_init[ind,ivar,:]
                else:
                    rla_best_estimate_var = rla_best_estimate_init[:,ivar,:]
        if 'climatology' in lead_time: rla_climatology_var = rla_climatology_init[:,ivar,:]
        if not ll_clim : 
            rla_climatology_var = rla_observation_var.copy()
            rla_climatology_var[:] = np.nan

    meminfo = psutil.Process().memory_info().rss / 2**20
    log.debug("RSS memory information : %s " %(str(meminfo)))
    # ---> Passe au jour suivant si pas de hindcast <---
    if np.isnan(rla_best_estimate_var).all(): 
        log.info("**********************************************")
        log.info("   Problem: missing best estimate               ")
        log.info("**********************************************")


    # ***************  quality control ***************

    if cexp == 'PHYS':
        rla_diffclim2obs = np.absolute(rla_climatology_var-rla_observation_var)
        rla_diffbest2obs = np.absolute(rla_best_estimate_var-rla_observation_var)
        qcs = np.where(rla_diffbest2obs > rg_EcartMax[cvar])
        if len(qcs[0]) > 0: rla_observation_var[qcs] = np.nan
        if type(rla_climatology_var) != float:
            if rla_climatology_var.any():
                qcs_clim = np.where(rla_diffclim2obs > rg_EcartMax[cvar])
                if len(qcs_clim[0]) > 0: rla_observation_var[qcs_clim] = np.nan
        if len(qcs[0]) > 0:
            rla_observation_var[qcs] = np.nan
        meminfo = psutil.Process().memory_info().rss / 2**20
        log.debug("RSS memory information QC : %s " %(str(meminfo)))
        if ll_ice:
            #qc_file= np.where(rla_qc_var == bad_qc[cvar] and  rla_qc_var2 == bad_qc[cvar])
            qc_file= np.where((rla_qc_var == bad_qc[cvar]) & (rla_qc_var2 == bad_qc[cvar]))
        elif ll_currents:
            #qc_file = np.where((rla_qc_var[:,1] != 1) & (rla_qc_var2 != 1) & (rla_qc_var3[:,1] != 1))
            qc_file = np.where((rla_qc_init[:,1] != 1) | (rla_qc_init2 != 1) | (rla_qc_init3[:,1] != 1)
                               | (rla_qc_init4[:,1] < 311))
                               #| (rla_qc_init4[:,1] != 313))
            #qc_file = np.where((rla_qc_init[:,1] != 1) | (rla_qc_init4[:,1] != 313))
            #print (rla_qc_init4[qc_file,1])
            #print (len(qc_file[0]))
            #print (len(rla_lonobs))
            percent = round((len(qc_file[0])*100)/len(rla_lonobs),2)
            print ("File %s Currents : Percentage of bad value %s%s " %(str(cl_cl4file),str(percent),'%'))
        else:
            qcvalues = bad_qc[cvar]
            if len(qcvalues) == 1:
                qc_file = np.where(rla_qc_var == int(qcvalues[0]))
            elif len(qcvalues) >= 2:
                qc_file = np.where(rla_qc_var >= int(qcvalues[0]))
            else:
                print ("No qc values")
                sys.exit(1)
        if len(qc_file[0]) > 0:
            rla_observation_var[qc_file] = np.nan
        w = np.where(np.isnan(rla_observation_var))
        rla_best_estimate_var[w] = np.nan
        if type(rla_climatology_var) != float:
            if rla_climatology_var.any():
                rla_climatology_var[w] = np.nan

        if 'forecast' in lead_time:
            for il in range(rla_forecast_var.shape[1]):
                rla_forecast_tmp = rla_forecast_var[:,il,:]
                rla_forecast_tmp[w] = np.nan
                rla_forecast_var[:,il,:] = rla_forecast_tmp
                del rla_forecast_tmp
                if 'persistence' in lead_time:
                    rla_persistence_tmp = rla_persistence_var[:,il,:]
                    rla_persistence_tmp[w] = np.nan
                    rla_persistence_var[:,il,:] = rla_persistence_tmp
                    del rla_persistence_tmp
    if cvar in ['VVEL', 'UVEL']:
        rla_observation_var = np.expand_dims(rla_observation_var[:,1], axis=1)
        rla_best_estimate_var = np.expand_dims(rla_best_estimate_var[:,1], axis=1)
        rla_climatology_var = np.expand_dims(rla_climatology_var[:,1], axis=1)
        rla_forecast_var = np.expand_dims(rla_forecast_var[:,:,1],axis=2)
        rla_persistence_var = np.expand_dims(rla_persistence_var[:,:,1], axis=2)
    if 'observation' in lead_time: dict_var[cvar]['observation'][str(num_date)] = rla_observation_var
    dict_var[cvar]['climatology'][str(num_date)] = rla_climatology_var
    if 'persistence' in lead_time: dict_var[cvar]['persistence'][str(num_date)] = rla_persistence_var
    if 'forecast' in lead_time: dict_var[cvar]['forecast'][str(num_date)] = rla_forecast_var
    if 'best_estimate' in lead_time: dict_var[cvar]['best_estimate'][str(num_date)] = rla_best_estimate_var

    return dict_var

def read_NC_tmp(statfile):
    """
        Read temporary netcdf file
    """

    nc = netCDF4.Dataset(statfile,'r')
    stat = nc.variables['stat_var'][:]
    fcst = nc.variables['forecast'][:]
    lead_time = nc.variables['lead_time'][:]
    leadtime = utils.pull_names(lead_time)
    if 'area_names' in nc.variables:
        area_names = nc.variables['area_names'][:]
    else:
        area_names = None
    nc.close()

    return stat, fcst, area_names, leadtime

def read_NC_skill_tmp(statfile):
    """
        Read temporary netcdf file
    """

    nc = netCDF4.Dataset(statfile,'r')
    stat_PSS_skill = nc.variables['skill_PSS_var'][:]
    stat_CSS_skill = nc.variables['skill_CSS_var'][:]
    lead_time = nc.variables['lead_time'][:]
    leadtime = utils.pull_names(lead_time)
    if 'area_names' in nc.variables:
        area_names = nc.variables['area_names'][:]
    else:
        area_names = None
    nc.close()
    return stat_PSS_skill, stat_CSS_skill, area_names, leadtime

