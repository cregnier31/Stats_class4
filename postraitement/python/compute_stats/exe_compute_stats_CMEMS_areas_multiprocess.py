#!/usr/bin/env python
# @Authors: "C. Szczypta & C.Regnier
# Program to compute CLASS4 statistics
# -*- coding: utf-8 -*-
import sys, os, getopt, glob, re
## Scientific utilities
import numpy as np
## MO Local modules
from os.path import dirname
sys.path.append(dirname(__file__)+'/../../../modules/')
import geomlib
import stats
import cl4_reader
import reader
import utils
from loader_post import input_params, read_input_files
import param.Def_param_bulletin as params
import arithm
import supobs
from supobs import toolkitStats
from supobs import Statslib
from writer_stat import writer_stat
from Logger import Logger
## Multiprocess
from mpi4py import MPI
## Timer/Cpu/Process utilities
import shlex, subprocess
import resource
import datetime as dt
import time
from timeit import default_timer as timer
import psutil


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                       DEFINE LOG AND MEMORY SIZE
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
#  Set logger
level = 2
start = timer()
log = Logger("CLASS4 Statistics").run(level)
ll_plot = False
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                       INPUT PARAMETERS SETTINGS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
params_conf, log = input_params(sys.argv[1:], log)

# Read input files
rla_surface, rla_layers, table_hull = read_input_files(
    params_conf)
params_conf['layers'] = rla_layers

# ***************************  Add a general timer  *************************

start = timer()

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                       INPUT MASKS
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
params_conf, rla_mask, rla_maskvalues, rla_mask_arc, rla_mask_ant,\
   rla_lonmask_nan, rla_latmask, rla_lonmask_nan_arc,\
   rla_latmask_arc, rla_lonmask_nan_ant, rla_latmask_ant = reader.mask2(params_conf)



if rla_lonmask_nan_arc is not None:
    rla_lonmask_nan_shift_arc = np.where(rla_lonmask_nan_arc<0, \
    rla_lonmask_nan_arc+360, rla_lonmask_nan_arc)
    rla_lonmask_nan_shift_ant = np.where(rla_lonmask_nan_ant<0, \
    rla_lonmask_nan_ant+360, rla_lonmask_nan_ant)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#                           LIST CLASS4 FILES
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Test input dir
#if not os.listdir(params_conf['dirNCin']):
#    log.error(params_conf['dirNCin']+" dirinput is not correct")
#    sys.exit(1)
#if not os.path.exists(os.path.join(params_conf['dirNCin'], params_conf['prefix']+'/*.nc')):
#    log.error(params_conf['dirNCin']+" dirinput is not correct")
#    sys.exit(1)

if params_conf['cexp'] == 'BIO':
    cla_varchck = glob.glob(os.path.join(params_conf['dirNCin'], params_conf['prefix']+'_'+params_conf['cla_dates'][0]+\
    '_'+params_conf['config_obs']+'_'+params_conf['config_model']+'_chl.nc'))
    if len(cla_varchck) == 1: cla_vars = ['chl']
    else: cla_vars = ['chl']
    bad_qc = np.nan
elif params_conf['cexp'] == 'PHYS' and params_conf['percent'] == 'off':
    cla_vars = []
    cla_vars_tmp = []
    for date in params_conf['cla_dates']:
        variables = [os.path.basename(file).split('_')[-1].split('.')[0] \
                     for file in glob.glob(os.path.join(params_conf['dirNCin']\
                     +params_conf['prefix']+'_'+date+'_'+params_conf['config_model']+'*nc'))]
        for var in variables:
            if var not in cla_vars_tmp:
                cla_vars_tmp.append(var)
                if var == "profile":
                    cla_vars.extend(('PSAL','TEMP'))
                elif var == "currents":
                    cla_vars.extend(('UVEL','VVEL'))
                else:
                    cla_vars.append(var)

elif params_conf['percent'] == 'on':
    cla_vars = ['PSAL','TEMP']
else:
    log.error(' Problem with the defined configuration')

# *********** check input repertory ***********
cl_file = params_conf['prefix']+'_*_'+params_conf['config_model']+'_*.nc'
cla_filechck = glob.glob(os.path.join(params_conf['dirNCin'], cl_file))
if len(cla_filechck) == 0:
    log.error(" Missing files ")
    log.error("Bad input repertory : {}".format(params_conf['dirNCin']))


# *********** MPI section to split dates on each processor ***********

comm = MPI.COMM_WORLD
ndates = len(params_conf['cla_dates'])
irest  = np.mod(ndates, comm.size)
ntask  = int(ndates / comm.size)
istart = int(ntask*comm.rank)
iend   = int(istart + ntask - 1)
cla_dt = params_conf['cla_dates'][istart:iend+1]
iend_tot = int(ntask*comm.size-1)
nb_fcst_max = 0
if irest > 0 and comm.rank < irest:
    cla_dt.append(params_conf['cla_dates'][iend_tot+comm.rank+1])

if comm.rank == 0:
    if not os.path.exists(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/'):
        os.makedirs(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/')

# *********************  Start main  *********************

if comm.rank == 0:
    log.info(' ______________________________ ')
    log.info('|                              |')
    log.info('|        Lecture CLASS4        |')
    log.info(' ------------------------------ ')


# ***************************************************************************
#                           DAILY STAT COMPUTATION
# ***************************************************************************

aname = []
nb_file_exist =  0
if params_conf['daily_off'] == 'on':
    for numvar, cvar in enumerate(cla_vars):

        if comm.rank == 0:
            log.info('')
            log.info("Variable: {} ".format(cvar))
            log.info('')

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #            READ TEP_CLASS4 NETCDF FILES AND COMPUTE DAILY STATS
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        # *************** Listing fichiers CLASS4 ***************

        for cdate in cla_dt:

            log.info('|   DATE: {} '.format(cdate))
            if params_conf['cexp'] == 'BIO':
                cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_obs']+\
                '_'+params_conf['config_model']+'_'+cvar+'.nc'
            else:
                if cvar in ['PSAL','TEMP']:
                    cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_model']+\
                    '_'+params_conf['cgrid']+'_profile.nc'
                elif cvar in ['UVEL','VVEL']:
                    cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_model']+\
                    '_'+params_conf['cgrid']+'_currents.nc'
                else:
                    cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_model']+\
                    '_'+params_conf['cgrid']+'_'+cvar+'.nc'
            cla_filechck = glob.glob(os.path.join(params_conf['dirNCin'],cl_file))

            if len(cla_filechck) != 1: continue
            else: cl_cl4file = cla_filechck[0]
            nb_file_exist +=  1

            log.debug("File class4 {}".format(cl_cl4file))

            # ******************  Read observations and model values  ******************
            dict_inputs = cl4_reader.read_inputfile(cvar, params_conf['cexp'], cl_cl4file, params_conf, log)
            if not dict_inputs:
                log.info("BEST FCST PERS are missing!! var: {}  file: {}".format(cvar,cl_cl4file))
                continue
            nb_fcst = dict_inputs['nb_fcst']
            if nb_fcst != None:
               if nb_fcst > nb_fcst_max : nb_fcst_max = nb_fcst
            lead_time = dict_inputs['lead_time']
            yout = dict_inputs['yout']

            # ---> Passe au jour suivant si pas de hindcast <---
            if np.isnan(dict_inputs['best']).all():
                log.info("Best estimate is nan {} {}!!".format(cdate,cvar))
                continue
            # **********************  Variable initialisation  **********************
            if nb_fcst == None:
                fmax = None
            elif nb_fcst == 1:
                fmax = 1
            else:
                fmax = nb_fcst//2

            if params_conf['CMEMS_area'] == True:
                stat_tmp = np.nan*np.zeros((dict_inputs['yout'], len(dict_inputs['tab_profs']) -1,\
                                            len(params_conf['cla_metricname']), len(params_conf['area_name'])))
                if params_conf['cexp'] == 'PHYS':
                    stat_PSS_skill = np.nan*np.zeros((fmax, len(dict_inputs['tab_profs']) -1, len(params_conf['area_name'])))
                    stat_CSS_skill = np.nan*np.zeros((fmax, len(dict_inputs['tab_profs']) -1, len(params_conf['area_name'])))
            if params_conf['CMEMS_area'] == False:
                stat_tmp = np.nan*np.zeros((dict_inputs['yout'], len(dict_inputs['tab_profs']) -1,\
                                            len(params_conf['cla_metricname']), len(rla_maskvalues)))
                if params_conf['cexp'] == 'PHYS':
                    stat_PSS_skill = np.nan*np.zeros((fmax, len(dict_inputs['tab_profs']) -1))
                    stat_CSS_skill = np.nan*np.zeros((fmax, len(dict_inputs['tab_profs']) -1))

            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            #             SELECTION OF GRID POINTS CONTAINED IN EACH BASIN
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            for area_mask in range(len(params_conf['area_name'])):
                if comm.rank == 0:
                    start_2 = timer()
                    log.debug(' Begining area {} '.format(params_conf['area_name'][area_mask]))
                if params_conf['CMEMS_area'] == True:
                    if params_conf['fmt_mask'] != "basin_pol":
                        rla_maskvalues = np.unique(rla_mask[area_mask,:,:])
                        rla_maskvalues = np.delete(rla_maskvalues,np.where(rla_maskvalues==0))
                        rla_maskvalues = np.delete(rla_maskvalues,np.where(np.isnan(rla_maskvalues)==True))
                    else:
                        rla_maskvalues = []
                        if area_mask < 16:
                            log.debug("Arctic region")
                            rla_mask = rla_mask_arc
                        else:
                            log.debug("Antarctic region")
                            rla_mask = rla_mask_ant
                        rla_maskvalues.append(params_conf['maskvalues'][area_mask])

                for imask,maskval in enumerate(rla_maskvalues):
                    if params_conf['CMEMS_area'] == False:
                        maskbox = rla_mask
                        amask = imask
                    else:
                        if params_conf['fmt_mask'] == "basin_pol":
                            if  maskval < 20 :
                                maskbox = rla_mask_arc[:,:]
                                rla_lonmask_nan = rla_lonmask_nan_arc
                                rla_lonmask_nan_shift = rla_lonmask_nan_shift_arc
                                rla_latmask = rla_latmask_arc
                            else:
                                maskbox = rla_mask_ant[:,:]
                                rla_lonmask_nan = rla_lonmask_nan_ant
                                rla_lonmask_nan_shift = rla_lonmask_nan_shift_ant
                                rla_latmask = rla_latmask_ant
                        else:
                            maskbox = rla_mask[area_mask,:,:]
                        amask = area_mask


                    # *********************************  Find observations in area  *****************************
                    if params_conf['cla_area'][area_mask] == 'GLO':
                        log.debug(' GLobal area {}')
                        iobs = np.arange(len(dict_inputs['latobs']))
                    else:
                        region = params_conf['area_name'][area_mask]
                        iobs = geomlib.search_points(params_conf['fmt_mask'], maskbox, maskval,\
                                        dict_inputs['lonobs'], dict_inputs['latobs'],\
                                        rla_lonmask_nan, rla_latmask, region, table_hull)

                    if np.size(iobs) == 0: continue
                    if ll_plot: utils.plot(iobs, dict_inputs['lonobs'], dict_inputs['latobs'],\
                            params_conf['cla_area'][area_mask], log)

                    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    #                       COMPUTE STATS FOR EACH BASIN
                    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    if comm.rank == 0:
                        log.debug("COMPUTE STATS FOR BASIN: {} ".format(params_conf['area_name'][area_mask]))
                    if params_conf['cexp'] == 'PHYS':
                        stats_tmp, stats_PSS_skill, stats_CSS_skill = stats.compute_stats_skill(lead_time, nb_fcst, iobs,\
                                                        dict_inputs, stat_tmp, stat_PSS_skill, stat_CSS_skill, amask,\
                                                        dict_inputs['yout'], log)
                    else:
                        stats_tmp = stats.compute_stats(lead_time, nb_fcst, iobs,\
                                                        dict_inputs, stat_tmp, amask, dict_inputs['yout'])

                if comm.rank == 0:
                    end_2 = timer()
                    log.debug('~~~~~~~~ Time elapsed : {} {}'.format
                            (str(end_2 - start_2), " seconds ~~~~~~~~~~~~"))

            # **********************  Save daily stats in netCDF format  **********************


            w = np.where(np.isnan(stats_tmp) == True)
            stats_tmp[w] = params_conf['missing_value']
            w = np.where(stats_tmp > params_conf['missing_value'])
            stats_tmp[w] = params_conf['missing_value']

            if params_conf['cexp'] == 'PHYS':
                missval = np.where(np.isnan(stats_PSS_skill) == True)
                stats_PSS_skill[missval] = params_conf['missing_value']
                miss = np.where(stats_PSS_skill > params_conf['missing_value'])
                stats_PSS_skill[missval] = params_conf['missing_value']
                missval = np.where(np.isnan(stats_CSS_skill) == True)
                stats_CSS_skill[missval] = params_conf['missing_value']
                miss = np.where(stats_CSS_skill > params_conf['missing_value'])
                stats_CSS_skill[missval] = params_conf['missing_value']
                missval = np.where(np.isnan(stats_CSS_skill) == True)
                cl_results_skill_tmp = os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cvar+'_skill_scores_'+cdate+'.nc')

            cl_results_tmp = os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cvar+'_'+cdate+'.nc')

            if params_conf['CMEMS_area'] == True:
                aname = params_conf['cla_area_names']
            else:
                aname = np.arange(len(rla_maskvalues))+1

            leadtime = np.chararray(len(lead_time), itemsize=14)

            for l in range(len(lead_time)):
                leadtime[l] = str(lead_time[l])
            if 'observation' in leadtime:
                leadtime = leadtime[1:]

            if len(stats_tmp[0,:,0,0]) > 1:
                writer_stat().write_daily_files(cl_results_tmp, aname, params_conf['cla_metricname'],\
                                                dict_inputs['rla_forecast'], rla_layers, stats_tmp,\
                                                params_conf['CMEMS_area'], leadtime, params_conf)

                if params_conf['cexp'] == 'PHYS':
                    writer_stat().write_daily_skill(cl_results_skill_tmp ,rla_layers, aname, \
                                                    stats_PSS_skill, stats_CSS_skill, params_conf['CMEMS_area'], fmax, params_conf)
                    del stats_PSS_skill
                    del stats_CSS_skill

                del stats_tmp
            else:
                writer_stat().write_daily_files(cl_results_tmp, aname, params_conf['cla_metricname'],\
                                                dict_inputs['rla_forecast'], rla_surface, stats_tmp,\
                                                params_conf['CMEMS_area'], leadtime, params_conf)

                if params_conf['cexp'] == 'PHYS':
                    writer_stat().write_daily_skill(cl_results_skill_tmp ,rla_surface, aname, \
                                                    stats_PSS_skill, stats_CSS_skill, params_conf['CMEMS_area'], fmax, params_conf)
                    del stats_PSS_skill
                    del stats_CSS_skill

                del stats_tmp


    comm.Barrier()

if params_conf['daily_off'] == 'on':

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #         SAVE RESULTS IN A SINGLE FILE FOR A CONSIDERED PERIOD
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    if params_conf['percent'] == 'off' and comm.rank == 0:

        if nb_file_exist  == 0:
            log.error("Missing files for this period {} {}" \
                    .format(params_conf['cl_start_date'],params_conf['cl_end_date']))
            sys.exit(1)

        writer_stat().write_stats_daily(params_conf,\
                                        cla_vars, rla_layers, rla_surface, log)

        if params_conf['cexp'] == 'PHYS' and dict_inputs['nb_fcst'] > 0: 
            writer_stat().write_stats_daily_skill(params_conf,\
                                                  cla_vars, rla_layers, rla_surface, log)


        end = timer()
        log.info(' ')
        log.info(" ~~~~~~~~~~~~~ Running time for daily stats : {} {} ".format(str(end - start), " seconds ~~~~~~~~~~~~"))
        log.info(' ')
        log.info(' ')
        log.info('**********************************************************************************')
        log.info('                         END OF DAILY COMPUTATION                ')
        log.info('**********************************************************************************')


    elif params_conf['percent'] == 'on':
        stat_all, rla_forecast, aname, lead_time = writer_stat().write_stats_daily(params_conf,\
                                                                                   cla_vars, rla_layers, rla_surface, log)

        w_obs = (np.where(params_conf['cla_metricname'] == 'mean of reference'))[0][0]
        w_nb_obs = (np.where(params_conf['cla_metricname'] == 'number of data values'))[0][0]
        w_mod = (np.where(params_conf['cla_metricname'] == 'mean of product'))[0][0]

        stat_bias = stat_all[:,:,:,w_mod,:,:]-stat_all[:,:,:,w_obs,:,:]
        nb_obs = stat_all[:,:,:,w_nb_obs,:,:]


        # *********** MPI section to split dates on each processor ***********


        comm = MPI.COMM_WORLD
        nareas = len(aname)
        irest  = np.mod(nareas, comm.size)
        ntask  = int(nareas / comm.size)
        istart = ntask*comm.rank
        iend   = istart + ntask - 1
        cla_ar = params_conf['cmems_basin'][istart:iend+1].tolist()
        iend_tot = ntask*comm.size-1
        if irest > 0 and comm.rank < irest:
            cla_ar.append(params_conf['cmems_basin'].tolist()[iend_tot+comm.rank+1])

        for area_name in cla_ar:
            ind = np.where(params_conf['cmems_basin'] == area_name)[0][0]
            stat_percent = np.nan*np.zeros((len(rla_forecast), len(rla_layers[0:-1]),\
                                            len(params_conf['metric_percent']), len(cla_vars)))

            stat_percent = writer_stat().compute_percentile(len(rla_forecast), len(rla_layers[0:-1]), len(cla_vars), stat_bias[:,:,:,ind,:], nb_obs[:,:,:,ind,:], stat_percent, params_conf)
            cl_resultsFileName = params_conf['prefix_fileout']+params_conf['cl_conf_percent']+'_'+\
                                 params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'_profile_percentile_'+area_name+'.nc'
            cl_resultsFile = os.path.join(params_conf['dirout'],cl_resultsFileName)

            leadtime = np.chararray(len(lead_time), itemsize=14)
            for l in range(len(lead_time)):
                leadtime[l] = str(lead_time[l])

            writer_stat().write_percent_files(cl_resultsFile, params_conf['metric_percent'], rla_forecast,
                                              rla_layers, stat_percent, leadtime, cla_vars, params_conf)

            del stat_percent

            log.info('**************************************************************************')
            log.info("              END OF DAILY COMPUTATION : {}".format(area_name))
            log.info('**************************************************************************')


        comm.Barrier()

    if comm.rank == 0:
        ## Cleanup
        for file in glob.glob(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/*.nc'):
            os.remove(file)


if comm.rank == 0 and params_conf['daily_off'] == 'on' and params_conf['bilan'] == 'on':

    # *********************** Start the timer again  *************************

    start = timer()
    log.info("Start Computation for the global")

# ***************************************************************************
#              STAT COMPUTATION OVER THE WHOLE CONSIDERED PERIOD
# ***************************************************************************

if params_conf['CMEMS_area'] == True:
    nareas = len(np.array(params_conf['area_name']))
else:
    nareas = len(rla_maskvalues)

comm = MPI.COMM_WORLD
irest  = np.mod(nareas,comm.size)
ntask  = int(nareas / comm.size)
istart = int(ntask*comm.rank)
iend   = int(istart + ntask - 1)
cla_zone = params_conf['cla_area'][istart:iend+1]
iend_tot = int(ntask*comm.size-1)
if irest > 0 and comm.rank < irest:
    cla_zone.append(params_conf['cla_area'][iend_tot+comm.rank+1])

recomb = 'off'

if params_conf['bilan'] == 'on' and recomb == 'off' :


    # *********** repartition dates sur processeurs ***********

    for numvar, cvar in enumerate(cla_vars):

        if comm.rank == 0:
            log.info('')
            log.info("Bilan on")
            log.info("Variable: {} ".format(cvar))
            log.info('')

        # *************** Listing fichiers CLASS4 ***************

        cla_cl4files = []

        for d, cdate in enumerate(params_conf['cla_dates']):
            if params_conf['cexp'] == 'BIO':
                cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_obs']+'_'+\
                        params_conf['config_model']+'_'+cvar+'.nc'
            else:
                if cvar in ['PSAL','TEMP']:
                    cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_model']+\
                            '_'+params_conf['cgrid']+'_profile.nc'
                elif cvar in ['UVEL','VVEL']:
                    cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_model']+\
                    '_'+params_conf['cgrid']+'_currents.nc'
                else:
                    cl_file = params_conf['prefix']+'_'+cdate+'_'+params_conf['config_model']+\
                            '_'+params_conf['cgrid']+'_'+cvar+'.nc'

            cla_filechck = glob.glob(os.path.join(params_conf['dirNCin'],cl_file))
            if len(cla_filechck) != 1: continue
            cla_cl4files.append(cla_filechck[0])
        if len(cla_cl4files) == 0:
            log.info("Missing files")
            log.info(params_conf['dirNCin']+cl_file)
            continue
        if params_conf['cexp'] == 'BIO' or cvar in ['SST', 'SLA','aice', 'UVEL', 'VVEL']:
            tab_prof   = np.array([-0.5,0.5])
        else:
            tab_prof = np.array(rla_layers)
        log.debug('Tab profs {}'.format(tab_prof))
        dict_inputs = cl4_reader.cfg_ltime(cla_cl4files[0], params_conf['cexp'], cvar)

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #             SELECTION OF GRID POINTS CONTAINED IN EACH BASIN
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        area_mask = None

        dict_var = {}
        dict_var[cvar] = {}
        dict_var[cvar]['depth_obs'] = {}
        for name_ech in dict_inputs['lead_time']:
            dict_var[cvar][name_ech] = {}
        dict_var[cvar]['longitude'] = {}
        dict_var[cvar]['latitude'] = {}

        if 'climatology' not in dict_inputs['lead_time']:
            log.info('clim is missing {}'.format(cl_file))
            dict_var[cvar]['climatology'] = {}

        ini_var = True
        nb_regions = len(cla_zone)
        log.debug("nb zones {} ".format(str(nb_regions)))
        if params_conf['ll_arc'] : min_lat = np.nanmin(rla_latmask)
        if params_conf['ll_ant'] : min_lat = np.nanmax(rla_latmask)
        for ar, area_mask in enumerate(cla_zone):
            area_m = np.where(np.array(params_conf['cla_area']) == area_mask)[0][0]

            if params_conf['CMEMS_area'] == True:
                rla_maskvalues = np.unique(rla_mask[area_m,:,:])
                rla_maskvalues = np.delete(rla_maskvalues,np.where(rla_maskvalues==0))

            stat_bilan = np.nan*np.zeros((dict_inputs['yout'], len(tab_prof) -1, len(params_conf['cla_metricname'])))
            stat_PSS_skill = np.nan*np.zeros((5, len(tab_prof) -1))
            stat_CSS_skill = np.nan*np.zeros((5, len(tab_prof) -1))
            if params_conf['CMEMS_area'] == False:
                maskbox = rla_mask
                maskval = rla_maskvalues[area_m]
            else:
                maskbox = rla_mask[area_m,:,:]
                maskval = rla_maskvalues[0]


            # **********************  Box definition  **********************

            ll_shift = False
            if area_mask != 'GLO':
                i,j = np.where(maskbox == maskval)
                boxlonmin = np.nanmin(rla_lonmask_nan[i,j])
                boxlonmax = np.nanmax(rla_lonmask_nan[i,j])

                # ~~~~~~~~ Test the min/max value of the box and shift in 0/360 if necessary ~~~~~~~

                if boxlonmin < 0 and boxlonmax > 0:
                    if boxlonmax > 179.9:

                        # ~~~~~~~~ Shift 0-360 ~~~~~~~~~~~~~~~~~~~

                        rla_lonmask_nan_shift = np.where(rla_lonmask_nan<0,rla_lonmask_nan+360,rla_lonmask_nan)
                        rla_lonmask_tmp = rla_lonmask_nan_shift
                        ll_shift = True
                    else:
                        rla_lonmask_tmp = rla_lonmask_nan
                else :
                    rla_lonmask_tmp = rla_lonmask_nan
                boxlonmin = np.nanmin(rla_lonmask_tmp[i,j])
                boxlonmax = np.nanmax(rla_lonmask_tmp[i,j])
                boxlatmin = np.nanmin(rla_latmask[i,j])
                boxlatmax = np.nanmax(rla_latmask[i,j])

            ilayer = 0
            dict = {}
            dict[area_mask] = {}
            for depthmin,depthmax in zip(tab_prof[:-1],tab_prof[1:]):

                OBS = [] ; CLIM = [] ; BEST = [] ; FCST = [] ; PERS = []
                dict_inputs['depthmin'] = depthmin
                dict_inputs['depthmax'] = depthmax
                log.debug('DEPTH: {0} {1} {2}{3}'.format(depthmin, '-',depthmax, 'm'))
                for num_date, cl_cl4file in enumerate(cla_cl4files):
                    if comm.rank == 0 and ar == 0:
                        log.debug("Read file : {} {}".format(cl_cl4file,num_date))
                        log.debug("Mask {} ".format(ar))
                        meminfo = psutil.Process().memory_info().rss / 2**20
                        log.debug("RSS memory information : {} ".format(meminfo))
                    # *********************  add observation positions  *********************
                    if ilayer == 0 and ini_var == True:
                        dict_var = cl4_reader.read_and_store_inputfiles(dict_inputs['lead_time'], cvar, params_conf['cexp'],\
                                                                        num_date, cl_cl4file, dict_var, params_conf['ll_arc'],\
                                                                        params_conf['ll_ant'], ll_shift, rla_latmask, log)

                    if ilayer == 0:
                        iobs = []
                        if params_conf['fmt_mask'] in ['basin', 'box', 'basin_pol']:
                            region=re.sub(' ','_',params_conf['area_name'][ar])
                        else:
                            region = "region_"+str(ar)
                        if region == 'Full_Domain':
                            iobs = np.arange(
                                len(dict_var[cvar]['latitude'][str(num_date)]))
                        else:
                            rla_lonobs_tmp = dict_var[cvar]['longitude'][str(num_date)]
                            rla_latobs = dict_var[cvar]['latitude'][str(num_date)]
                            iobs = geomlib.search_points(params_conf['fmt_mask'], maskbox,\
                                                         maskval, rla_lonobs_tmp, rla_latobs,\
                                                         rla_lonmask_nan, rla_latmask, region, table_hull)

                        dict[area_mask][str(num_date)] = iobs

                    else:
                        iobs = dict[area_mask][str(num_date)]
                    if comm.rank == 0 and ar == 0:
                        meminfo = psutil.Process().memory_info().rss / 2**20
                        log.debug("RSS memory information 8 : {} ".format(meminfo))
                        log.debug( '--------------------------------------------------' )
                    if np.size(iobs) == 0:
                        continue
                    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                    #                       COMPUTE STATS
                    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

                    # ***************  Compute Stats at each lead time ***************

                    OBS, CLIM, BEST, FCST, PERS  = stats.compute_stats_and_extend(dict_inputs, dict_var, dict,\
                                                                                  cvar, num_date, area_mask, OBS, CLIM,\
                                                                                  BEST, FCST, PERS)

                if params_conf['cexp'] == 'PHYS':
                    stat_bilan, stat_PSS_skill, stat_CSS_skill = stats.compute_stats_bilan_skill(dict_inputs, stat_bilan, \
                                                                    stat_PSS_skill, stat_CSS_skill, ilayer,\
                                                                    OBS, BEST, FCST, PERS, CLIM, log)
                else:
                    stat_bilan = stats.compute_stats_bilan(dict_inputs, stat_bilan, ilayer,\
                                                            OBS, BEST, FCST, PERS, CLIM, log)

                ilayer += 1

            ini_var = False
            w = np.where(np.isnan(stat_bilan) == True)
            stat_bilan[w] = params_conf['missing_value']
            w = np.where(stat_bilan > params_conf['missing_value'])
            stat_bilan[w] = params_conf['missing_value']
            if params_conf['cexp'] == 'PHYS':
                w = np.where(np.isnan(stat_PSS_skill) == True)
                stat_PSS_skill[w] = params_conf['missing_value']
                w = np.where(stat_PSS_skill > params_conf['missing_value'])
                stat_PSS_skill[w] = params_conf['missing_value']
                w = np.where(np.isnan(stat_CSS_skill) == True)
                stat_CSS_skill[w] = params_conf['missing_value']
                w = np.where(stat_CSS_skill > params_conf['missing_value'])
                stat_CSS_skill[w] = params_conf['missing_value']
                cl_resultsFileName_bilan_skill = 'glob_mean_quality_stats_'+cvar+'_'+str(area_mask)+\
                                            '_'+params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'_skill.nc'
                cl_resultsFile_bilan_skill = os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_resultsFileName_bilan_skill)


            if 'climatology' not in dict_inputs['lead_time']:
                leadtime = np.chararray(len(dict_inputs['lead_time'])+1, itemsize=14)
                for l in range(len(dict_inputs['lead_time'])):
                    leadtime[l] = str(dict_inputs['lead_time'][l])
                leadtime[l+1]  = "climatology"
            else:
                leadtime = np.chararray(len(dict_inputs['lead_time']), itemsize=14)
                for l in range(len(dict_inputs['lead_time'])):
                    leadtime[l] = str(dict_inputs['lead_time'][l])
            if 'observation' in leadtime:
                leadtime = leadtime[1:]

            cl_resultsFileName_bilan = 'glob_mean_quality_stats_'+cvar+'_'+str(area_mask)+\
                                        '_'+params_conf['cl_start_date']+'_'+params_conf['cl_end_date']+'.nc'
            cl_resultsFile_bilan = os.path.join(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/',cl_resultsFileName_bilan)

            if np.size(stat_bilan[0,:,0]) > 1:
                writer_stat().write_glob_files_area(cl_resultsFile_bilan, params_conf['cla_metricname'], \
                                                    dict_inputs['rla_forecast'], rla_layers, stat_bilan, leadtime, params_conf)
                if params_conf['cexp'] == 'PHYS':
                    log.debug("Write file {} ".format(cl_resultsFile_bilan_skill))
                    writer_stat().write_glob_files_area_skill(cl_resultsFile_bilan_skill, rla_layers, stat_PSS_skill, stat_CSS_skill, params_conf)
                    del stat_PSS_skill, stat_CSS_skill
                del stat_bilan
            else:
                writer_stat().write_glob_files_area(cl_resultsFile_bilan, params_conf['cla_metricname'],\
                                                    dict_inputs['rla_forecast'], rla_surface, stat_bilan, leadtime, params_conf)
                if params_conf['cexp'] == 'PHYS':
                    writer_stat().write_glob_files_area_skill(cl_resultsFile_bilan_skill, rla_surface, stat_PSS_skill, stat_CSS_skill, params_conf)
                    del stat_PSS_skill, stat_CSS_skill
                del stat_bilan
            del dict
        if comm.rank == 0 and ar == 0:
            meminfo = psutil.Process().memory_info().rss / 2**20
            log.debug("RSS memory information : {} ".format(meminfo))

        del dict_var

    comm.Barrier()
    recomb = 'on'


if comm.rank == 0 and params_conf['bilan'] == 'on':

    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #                     SAVE RESULTS IN A SINGLE FILE
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    writer_stat().write_stats_BOX(params_conf,\
                                    cla_vars, rla_layers, rla_surface, rla_maskvalues)
    if params_conf['cexp'] == 'PHYS':
        writer_stat().write_stats_BOX_skill(params_conf,\
                                            cla_vars, rla_layers, rla_surface, rla_maskvalues)
    end = timer()
    log.info(' ')
    log.info(" ~~~~~~~~~~~~ Running time for global stats: {} {} ".format(str(end - start), " seconds ~~~~~~~~~~~~"))
    log.info(' ')
    log.info(' ')
    log.info('**********************************************************************************')
    log.info('                             END OF GLOBAL STATS COMPUTATION                      ')
    log.info('**********************************************************************************')
    ## Cleanup
    for file in glob.glob(params_conf['dirout']+'TMP/*.nc'):
        os.remove(file)
    for file in glob.glob(params_conf['dirout']+'TMP_'+params_conf['cla_dates'][0]+'_'+params_conf['cla_dates'][-1]+'/*.nc'):
        os.remove(file)
