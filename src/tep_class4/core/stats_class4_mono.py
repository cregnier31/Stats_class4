#!/usr/bin/env python
# @Authors: "C.Regnier
# Program to compute CLASS4 statistics
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
"""
Description:
    New CLASS4 launcher to compute CLASS4 statistics for all the computed CLASS4 files
History:
    April 2025      : Edito version

Developer:
    C. REGNIER
"""

import os
from os.path import dirname
import glob
import re
import traceback
import numpy as np
import resource
from timeit import default_timer as timer
import pickle
import gc
import psutil
import argparse

# Import local modules
import tep_class4.core.cl4errors as cl4err
import tep_class4.core.geomlib
import tep_class4.core.stats
import tep_class4.core.cl4_reader
import tep_class4.core.reader
import tep_class4.core.utils
from tep_class4.core.loader_post import input_params, read_input_files
from tep_class4.core.writer_stat import writer_stat
from tep_class4.core.Logger import Logger
import tep_class4.core.param.Def_param_bulletin as params
#  Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY,
                                           resource.RLIM_INFINITY))
def main(level=2):
    #  Set logger
    level = 2
    start = timer()
    log = Logger("CLASS4 Statistics").run(level)
    ll_plot = False
    ll_skill = False
    ll_pickle = True
    if ll_pickle:
        suf = ".p"
    else:
        suf = ".nc"
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
       rla_latmask_arc, rla_lonmask_nan_ant, rla_latmask_ant = \
       reader.mask2(params_conf)
    if rla_lonmask_nan_arc is not None:
        rla_lonmask_nan_shift_arc = np.where(rla_lonmask_nan_arc < 0,
                                             rla_lonmask_nan_arc+360,
                                             rla_lonmask_nan_arc)
        rla_lonmask_nan_shift_ant = np.where(rla_lonmask_nan_ant < 0,
                                             rla_lonmask_nan_ant+360,
                                             rla_lonmask_nan_ant)
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #                           LIST CLASS4 FILES
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    log.debug('LIST CLASS4 FILES')
    # *********** check input repertory ***********
    cl_file = params_conf['prefix']+'_*_'+params_conf['config_model']+'_*.nc'
    cla_filechck = glob.glob(os.path.join(params_conf['dirNCin'], cl_file))
    if len(cla_filechck) == 0:
        log.error(" Missing files ")
        log.error("Bad input repertory : {}".format(params_conf['dirNCin']))
    try:
        if params_conf['cexp'] == 'BIO':
            log.debug('Bio case')
            names_files = (f"{params_conf['dirNCin']}{params_conf['prefix']}_"
                           f"{params_conf['cla_dates'][0]}_"
                           f"{params_conf['config_obs']}_"
                           f"{params_conf['config_model']}_chl.nc")
            cla_varchck = glob.glob(names_files)
            if len(cla_varchck) == 1:
                cla_vars = ['chl']
            else:
                cla_vars = ['chl']
            bad_qc = np.nan
        elif params_conf['cexp'] == 'PHYS' and params_conf['percent'] == 'off':
            log.debug('Phys case')
            cla_vars = []
            cla_vars_tmp = []
            log.debug(f'List of dates {params_conf["cla_dates"]}')
            log.debug(f"Prefix = {params_conf['prefix']}"
                      f"Model = {params_conf['config_model']}")
            for date in params_conf['cla_dates']:
                name_files = (f"{params_conf['dirNCin']}{params_conf['prefix']}_"
                              f"{date}_{params_conf['config_model']}*nc")
                log.debug(f'{name_files=}')
                variables = [os.path.basename(file).split('_')[-1].split('.')[0]
                             for file in glob.glob(name_files)]
                log.debug(f'{variables=}')
                for var in variables:
                    if var not in cla_vars_tmp:
                        cla_vars_tmp.append(var)
                        if var == "profile":
                            cla_vars.extend(('TEMP', 'PSAL'))
                        elif var == "temp-profile":
                            self.log.debug("no other variable")
                        #    cla_vars.extend(['TEMP'])
                        elif var == "currents":
                            cla_vars.extend(('UVEL', 'VVEL'))
                        elif var == "currents-filtr":
                            cla_vars.extend(('UVEL_filtr', 'VVEL_filtr'))
                        else:
                            cla_vars.append(var)
            # Remove empty value
            cla_vars = list(filter(None, cla_vars))
            cla_vars = sorted(cla_vars, key=lambda s: s.lower())
            log.debug(f'List of variables {cla_vars}')
            if not cla_vars:
                raise cl4err.Class4FatalError('Missing input files'
                                              'for these dates!!')
        elif params_conf['percent'] == 'on':
            #cla_vars = ['PSAL', 'TEMP']
            cla_vars = ['TEMP', 'PSAL']
        else:
            log.error('Problem with the defined configuration')
    except Exception as e:
        log.error(f"Error {traceback.format_exc()}{e}")
        sys.exit(1)
    # *********** MPI section to split dates on each processor ***********
    cla_dt = params_conf['cla_dates'][:]
    nb_fcst_max = 0
    name_dir = (f"{params_conf['dirout']}TMP_{params_conf['cla_dates'][0]}_"
               f"{params_conf['cla_dates'][-1]}/")
    if not os.path.exists(name_dir):
       os.makedirs(name_dir)

    # *********************  Start main  *********************
    log.info(' ______________________________ ')
    log.info('|                              |')
    log.info('|        Lecture CLASS4        |')
    log.info(' ------------------------------ ')

    # ***************************************************************************
    #                           DAILY STAT COMPUTATION
    # ***************************************************************************

    aname = []
    nb_file_exist = 0
    tab_class4 = {}
    tab_class4['TEMP'] = 'profile'
    #tab_class4['PSAL'] = 'profile'
    tab_class4['UVEL'] = 'currents'
    tab_class4['VVEL'] = 'currents'
    tab_class4['UVEL_filtr'] = 'currents-filtr'
    tab_class4['VVEL_filtr'] = 'currents-filtr'
    tab_class4['SST'] = 'SST'
    tab_class4['SLA'] = 'SLA'

    if params_conf['daily_off'] == 'on':
        for numvar, cvar in enumerate(cla_vars):

            log.info('')
            log.info("Variable: {} ".format(cvar))
            log.info('')
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            #   READ TEP_CLASS4 NETCDF FILES AND COMPUTE DAILY STATS
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            # *************** Listing fichiers CLASS4 ***************

            for cdate in cla_dt:

                log.debug('|   DATE: {} '.format(cdate))
                log.debug(f"Experience {params_conf['cexp']}")
                if params_conf['cexp'] == 'BIO':
                    cl_file = (f"{params_conf['prefix']}_{cdate}_"
                               f"{params_conf['config_obs']}_"
                               f"{params_conf['config_model']}_{cvar}.nc")
                else:
                    ##
                    if cvar == 'PSAL':
                        varname = 'profile'
                        cl_file = (f"{params_conf['prefix']}_{cdate}_"
                                   f"{params_conf['config_model']}_"
                                   f"{params_conf['cgrid']}_{varname}.nc")
                    elif cvar in tab_class4.keys():
                        varname = tab_class4[cvar]
                        cl_file = (f"{params_conf['prefix']}_{cdate}_"
                                   f"{params_conf['config_model']}_"
                                   f"{params_conf['cgrid']}_*{varname}.nc")
                    else:
                        varname = cvar
                        cl_file = (f"{params_conf['prefix']}_{cdate}_"
                                   f"{params_conf['config_model']}_"
                                   f"{params_conf['cgrid']}_{varname}.nc")
                    #if cvar in tab_class4.keys():
                    #    varname = tab_class4[cvar]
                    #else:
                    #    varname = cvar
                ll_weight = params.rg_cptwgt[cvar]
                    #cl_file = (f"{params_conf['prefix']}_{cdate}_"
                    #           f"{params_conf['config_model']}_"
                    #           f"{params_conf['cgrid']}_*{varname}.nc")
                cla_filechck = glob.glob(f"{params_conf['dirNCin']}{cl_file}")
                if len(cla_filechck) != 1:
                    log.info(f"File is missing {params_conf['dirNCin']}"
                              f"{cl_file}")
                    continue
                else:
                    cl_cl4file = cla_filechck[0]
                nb_file_exist += 1

                log.info(f"File class4 {cl_cl4file}")
                # **********  Read observations and model values  ***********
                dict_inputs = cl4_reader.read_inputfile(cvar,
                                                        params_conf['cexp'],
                                                        cl_cl4file,
                                                        params_conf,
                                                        log)
                if not dict_inputs:
                    log.info(f'BEST FCST PERS are missing!! var:'
                             f'{cvar} {cl_cl4file}')
                    continue
                nb_fcst = dict_inputs['nb_fcst']
                if nb_fcst is not None:
                    if nb_fcst > nb_fcst_max:
                        nb_fcst_max = nb_fcst
                lead_time = dict_inputs['lead_time']
                yout = dict_inputs['yout']

                # ---> Passe au jour suivant si pas de hindcast ni forecast <---
                if np.isnan(dict_inputs['best']).all() and np.isnan(dict_inputs['frcst']).all():
                    log.info(f'Best estimate and forecast are nan {cdate} {cvar}')
                    continue
                # *******************  Variable initialisation  *******************
                if nb_fcst is None:
                    fmax = None
                elif nb_fcst == 1:
                    fmax = 1
                else:
                    fmax = nb_fcst//2

                if params_conf['CMEMS_area'] is True:
                    stat_tmp = \
                            np.nan*np.zeros((dict_inputs['yout'],
                                             len(dict_inputs['tab_profs']) - 1,
                                             len(params_conf['cla_metricname']),
                                             len(params_conf['area_name'])))
                    if params_conf['cexp'] == 'PHYS' and ll_skill:
                        stat_PSS_skill = \
                                np.nan*np.zeros((fmax,
                                                 len(dict_inputs['tab_profs']) - 1,
                                                 len(params_conf['area_name'])))
                        stat_CSS_skill = \
                            np.nan*np.zeros((fmax,
                                             len(dict_inputs['tab_profs']) - 1,
                                             len(params_conf['area_name'])))
                if params_conf['CMEMS_area'] is False:
                    stat_tmp = \
                        np.nan*np.zeros((dict_inputs['yout'],
                                         len(dict_inputs['tab_profs']) - 1,
                                         len(params_conf['cla_metricname']),
                                         len(rla_maskvalues)))
                    if params_conf['cexp'] == 'PHYS' and ll_skill:
                        stat_PSS_skill = \
                                np.nan*np.zeros((
                                    fmax,
                                    len(dict_inputs['tab_profs']) - 1
                                    ))
                        stat_CSS_skill = \
                            np.nan*np.zeros((
                                fmax,
                                len(dict_inputs['tab_profs']) - 1
                                ))

                # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                #         SELECTION OF GRID POINTS CONTAINED IN EACH BASIN
                # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

                for area_mask in range(len(params_conf['area_name'])):
                    start_2 = timer()
                    log.debug(f"Area {params_conf['area_name'][area_mask]}")
                    if params_conf['CMEMS_area'] is True:
                        if params_conf['fmt_mask'] != "basin_pol":
                            rla_maskvalues = np.unique(rla_mask[area_mask, :, :])
                            rla_maskvalues = \
                                np.delete(rla_maskvalues,
                                          np.where(rla_maskvalues == 0))
                            condition = np.isnan(rla_maskvalues) is True
                            rla_maskvalues = np.delete(rla_maskvalues,
                                                       np.where(condition))
                        else:
                            rla_maskvalues = []
                            if area_mask < 16:
                                log.debug("Arctic region")
                                rla_mask = rla_mask_arc
                            else:
                                log.debug("Antarctic region")
                                rla_mask = rla_mask_ant
                            rla_maskvalues.append(
                                    params_conf['maskvalues'][area_mask])

                    for imask, maskval in enumerate(rla_maskvalues):
                        if params_conf['CMEMS_area'] is False:
                            maskbox = rla_mask
                            amask = imask
                        else:
                            if params_conf['fmt_mask'] == "basin_pol":
                                if maskval < 20:
                                    maskbox = rla_mask_arc[:, :]
                                    rla_lonmask_nan = rla_lonmask_nan_arc
                                    rla_lonmask_nan_shift = \
                                        rla_lonmask_nan_shift_arc
                                    rla_latmask = rla_latmask_arc
                                else:
                                    maskbox = rla_mask_ant[:, :]
                                    rla_lonmask_nan = rla_lonmask_nan_ant
                                    rla_lonmask_nan_shift = \
                                        rla_lonmask_nan_shift_ant
                                    rla_latmask = rla_latmask_ant
                            else:
                                maskbox = rla_mask[area_mask, :, :]
                            amask = area_mask

                        # **************  Find observations in area  **************
                        if params_conf['cla_area'][area_mask] == 'GLO':
                            log.debug(' GLobal area {}')
                            iobs = np.arange(len(dict_inputs['latobs']))
                        else:
                            region = params_conf['area_name'][area_mask]
                            iobs = geomlib.search_points(params_conf['fmt_mask'],
                                                         maskbox,
                                                         maskval,
                                                         dict_inputs['lonobs'],
                                                         dict_inputs['latobs'],
                                                         rla_lonmask_nan,
                                                         rla_latmask,
                                                         region,
                                                         table_hull)

                        if np.size(iobs) == 0:
                            continue
                        if ll_plot:
                            utils.plot(iobs,
                                       dict_inputs['lonobs'],
                                       dict_inputs['latobs'],
                                       params_conf['cla_area'][area_mask],
                                       log)

                        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        #                       COMPUTE STATS FOR EACH BASIN
                        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        log.debug((f"COMPUTE STATS FOR BASIN:"
                                   f"{params_conf['area_name'][area_mask]}"))
                        if params_conf['cexp'] == 'PHYS' and ll_skill:
                            stats_tmp, stats_PSS_skill, stats_CSS_skill = \
                                    stats.compute_stats_skill(lead_time,
                                                              nb_fcst,
                                                              iobs,
                                                              dict_inputs,
                                                              stat_tmp,
                                                              stat_PSS_skill,
                                                              stat_CSS_skill,
                                                              amask,
                                                              dict_inputs['yout'],
                                                              ll_weight,
                                                              log)
                        elif params_conf['cexp'] == 'PHYS' and not ll_skill:
                            log.debug("COMPUTE STATS FOR BASIN no skill")
                            stats_tmp = stats.compute_stats(lead_time,
                                                            nb_fcst,
                                                            iobs,
                                                            dict_inputs,
                                                            stat_tmp,
                                                            amask,
                                                            dict_inputs['yout'],
                                                            ll_weight,
                                                            log)
                            log.debug("COMPUTE STATS FOR BASIN no skill ok")
                        else:
                            stats_tmp = stats.compute_stats(lead_time,
                                                            nb_fcst,
                                                            iobs,
                                                            dict_inputs,
                                                            stat_tmp,
                                                            amask,
                                                            ll_weight,
                                                            dict_inputs['yout'],
                                                            log)

                    end_2 = timer()
                    log.debug(f'~ Time elapsed : {end_2 - start_2} seconds ~')

                # ************  Save daily stats in netCDF format  ***************

                w = np.where(np.isnan(stats_tmp) is True)
                stats_tmp[w] = params_conf['missing_value']
                w = np.where(stats_tmp > params_conf['missing_value'])
                stats_tmp[w] = params_conf['missing_value']

                if params_conf['cexp'] == 'PHYS' and ll_skill:
                    missval = np.where(np.isnan(stats_PSS_skill) is True)
                    stats_PSS_skill[missval] = params_conf['missing_value']
                    miss = np.where(stats_PSS_skill > params_conf['missing_value'])
                    stats_PSS_skill[missval] = params_conf['missing_value']
                    missval = np.where(np.isnan(stats_CSS_skill) is True)
                    stats_CSS_skill[missval] = params_conf['missing_value']
                    miss = np.where(stats_CSS_skill > params_conf['missing_value'])
                    stats_CSS_skill[missval] = params_conf['missing_value']
                    missval = np.where(np.isnan(stats_CSS_skill) is True)
                    cl_results_skill_tmp = (f"{params_conf['dirout']}"
                                            f"TMP_{params_conf['cla_dates'][0]}_"
                                            f"{params_conf['cla_dates'][-1]}/"
                                            f"{cvar}_skill_scores_{cdate}.nc")
                nameout_skill_nc = (f"{params_conf['dirout']}"
                                    f"TMP_{params_conf['cla_dates'][0]}_"
                                    f"{params_conf['cla_dates'][-1]}/"
                                    f"{cvar}_{cdate}.nc")
                nameout_skill_p = re.sub('.nc', '.p', nameout_skill_nc)
                cl_results_tmp = nameout_skill_nc
                cl_results_tmp_p = nameout_skill_p

                if params_conf['CMEMS_area'] is True:
                    aname = params_conf['cla_area_names']
                else:
                    aname = np.arange(len(rla_maskvalues))+1

                leadtime = np.chararray(len(lead_time), itemsize=14)
                for lead in range(len(lead_time)):
                    leadtime[lead] = str(lead_time[lead])
                if 'observation' in leadtime:
                    leadtime = leadtime[1:]

                if len(stats_tmp[0, :, 0, 0]) > 1:
                    # Modif charly
                    if ll_pickle:
                        with open(cl_results_tmp_p, 'wb') as f:
                            pickle.dump(stat_tmp, f, pickle.HIGHEST_PROTOCOL)
                    else:
                        writer_stat().write_daily_files(
                                cl_results_tmp,
                                aname,
                                params_conf['cla_metricname'],
                                dict_inputs['rla_forecast'],
                                rla_layers,
                                stats_tmp,
                                params_conf['CMEMS_area'],
                                leadtime,
                                params_conf)

                    if params_conf['cexp'] == 'PHYS' and ll_skill:
                        writer_stat().write_daily_skill(cl_results_skill_tmp,
                                                        rla_layers,
                                                        aname,
                                                        stats_PSS_skill,
                                                        stats_CSS_skill,
                                                        params_conf['CMEMS_area'],
                                                        fmax,
                                                        params_conf)
                        del stats_PSS_skill
                        del stats_CSS_skill

                    del stats_tmp
                else:
                    if ll_pickle:
                        try:
                            with open(cl_results_tmp_p, 'wb') as f:
                                pickle.dump(stat_tmp,
                                            f,
                                            pickle.HIGHEST_PROTOCOL)
                        except Exception as e:
                            self.log.error(f'Missing {cl_results_tmp_p}{e}')
                    else:
                        writer_stat().write_daily_files(
                                cl_results_tmp,
                                aname,
                                params_conf['cla_metricname'],
                                dict_inputs['rla_forecast'],
                                rla_surface,
                                stats_tmp,
                                params_conf['CMEMS_area'],
                                leadtime,
                                params_conf)

                    if params_conf['cexp'] == 'PHYS' and ll_skill:
                        writer_stat().write_daily_skill(
                                cl_results_skill_tmp,
                                rla_surface, aname,
                                stats_PSS_skill,
                                stats_CSS_skill,
                                params_conf['CMEMS_area'],
                                fmax,
                                params_conf)
                        del stats_PSS_skill
                        del stats_CSS_skill

                    del stats_tmp


    if params_conf['daily_off'] == 'on':

        log.debug("Daily off on save results {params_conf['percent']}")
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #         SAVE RESULTS IN A SINGLE FILE FOR A CONSIDERED PERIOD
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        if params_conf['percent'] == 'off':

            if nb_file_exist == 0:
                log.error((f"Missing files for this period "
                           f"{params_conf['cl_start_date']}"
                           f"{params_conf['cl_end_date']}"))
                sys.exit(1)
            #
            log.debug(f"write_stats_daily {lead_time} {ll_pickle}")
            writer_stat().write_stats_daily(
                    params_conf,
                    cla_vars,
                    rla_layers,
                    rla_surface,
                    dict_inputs['rla_forecast'],
                    leadtime,
                    ll_pickle,
                    log)

            if params_conf['cexp'] == 'PHYS' and \
                    dict_inputs['nb_fcst'] and ll_skill:
                writer_stat().write_stats_daily_skill(
                        params_conf,
                        cla_vars,
                        rla_layers,
                        rla_surface,
                        log)

            end = timer()
            log.info(' ')
            log.info(f'~ Running time for daily stats {end - start} seconds ~')
            log.info(' ')
            log.info(' ')
            log.info('*******************************************************')
            log.info('                END OF DAILY COMPUTATION                  ')
            log.info('**********************************************************')

        elif params_conf['percent'] == 'on':
            log.debug(f"write_stats_daily percent {rla_layers=} {rla_surface=}")
            log.debug(f"write_stats_daily percent {dict_inputs['rla_forecast']=}")
            log.debug(f"write_stats_daily percent {leadtime=} {ll_pickle=}")

            stat_all, rla_forecast, aname, lead_time = \
                    writer_stat().write_stats_daily(params_conf,
                                                    cla_vars,
                                                    rla_layers,
                                                    rla_surface,
                                                    dict_inputs['rla_forecast'],
                                                    leadtime,
                                                    ll_pickle,
                                                    log)

            name1 = 'mean of reference'
            name2 = 'number of data values'
            name3 = 'mean of product'
            name4 = 'mean squared error'
            metrics = [var.decode("utf-8") for var in params_conf['cla_metricname']]
            w_obs = metrics.index(name1)
            w_nb_obs = metrics.index(name2)
            w_mod = metrics.index(name3)
            w_rmse = metrics.index(name4)
            #w_obs = (np.where(
            #    params_conf['cla_metricname'] == name1))[0][0]
            #w_nb_obs = (
            #    np.where(params_conf['cla_metricname'] == name2))[0][0]
            #w_mod = (
            #    np.where(params_conf['cla_metricname'] == name3))[0][0]

            #stat_bias = stat_all[:, :, :, w_mod, :, :] - \
            #    stat_all[:, :, :, w_obs, :, :]
            stat_mod = np.nan_to_num(stat_all[:, :, :, w_mod, :, :], nan=0)
            stat_obs = np.nan_to_num(stat_all[:, :, :, w_obs, :, :], nan=0)
            nb_obs = np.nan_to_num(stat_all[:, :, :, w_nb_obs, :, :], nan=0)
            stats_rmse = np.nan_to_num(stat_all[:, :, :, w_rmse, :, :], nan=0)
            # Compute the squared differences
            #squared_diff = np.square(stat_mod - stat_obs)
            #print(stats_rmse[:, 0, :, 5, 0])
            # Compute the squared differences
            squared_diff = stats_rmse
            stat_bias = (stat_mod - stat_obs)
            #stat_bias = stat_all[:, :, :, w_mod, :, :] - \
            #    stat_all[:, :, :, w_obs, :, :]
            #squared_diff = np.square(stat_all[:, :, :, w_mod, :, :] - \
            #               stat_all[:, :, :, w_obs, :, :])

            #nb_obs = stat_all[:, :, :, w_nb_obs, :, :]
            #stat_mod = stat_all[:, :, :, w_mod, :, :]
            #stat_obs = stat_all[:, :, :, w_obs, :, :]

            # *********** MPI section to split dates on each processor ********

            cla_ar = params_conf['cmems_basin'][:].tolist()

            for area_name in cla_ar:
                ind = np.where(params_conf['cmems_basin'] == area_name)[0][0]
                area_name_utf8 = area_name.decode("utf-8")
                stat_percent = np.nan*np.zeros((
                    len(rla_forecast),
                    len(rla_layers[0:-1]),
                    len(params_conf['metric_percent']),
                    len(cla_vars)
                    ))

                stat_percent = writer_stat().compute_percentile(
                        len(rla_forecast),
                        len(rla_layers[0:-1]),
                        len(cla_vars),
                        stat_bias[:, :, :, ind, :],
                        squared_diff[:, :, :, ind, :],
                        stat_obs[:, :, :, ind, :],
                        stat_mod[:, :, :, ind, :],
                        nb_obs[:, :, :, ind, :],
                        stat_percent,
                        params_conf)
                self.log.debug(stat_percent[0, :, 11, 0])

                cl_resultsFileName = (f"{params_conf['prefix_fileout']}"
                                      f"{params_conf['cl_conf_percent']}_"
                                      f"{params_conf['cl_start_date']}_"
                                      f"{params_conf['cl_end_date']}_"
                                      f"profile_percentile_{area_name_utf8}.nc")
                cl_resultsFile = f"{params_conf['dirout']}{cl_resultsFileName}"

                leadtime = np.chararray(len(lead_time), itemsize=14)
                for lead in range(len(lead_time)):
                    leadtime[lead] = str(lead_time[lead])

                writer_stat().write_percent_files(
                        cl_resultsFile,
                        params_conf['metric_percent'],
                        rla_forecast,
                        rla_layers,
                        stat_percent,
                        leadtime,
                        cla_vars,
                        params_conf
                        )

                del stat_percent

                log.info('*****************************************************')
                log.info(f"   END OF DAILY COMPUTATION : {area_name}")
                log.info('*****************************************************')


        # Cleanup
        list_names = (f"{params_conf['dirout']}"
                      f"TMP_{params_conf['cla_dates'][0]}_"
                      f"{params_conf['cla_dates'][-1]}/*{suf}")
        log.info(f'Remove files {list_names}')
        for file in glob.glob(list_names):
            os.remove(file)


    if params_conf['daily_off'] == 'on'\
            and params_conf['bilan'] == 'on':

        # *********************** Start the timer again  *************************

        start = timer()
        log.info("Daily off on and bilan on start computation")
        log.info("Start Computation for the global")

    # ***************************************************************************
    #              STAT COMPUTATION OVER THE WHOLE CONSIDERED PERIOD
    # ***************************************************************************

    if params_conf['CMEMS_area'] is True:
        nareas = len(np.array(params_conf['area_name']))
    else:
        nareas = len(rla_maskvalues)

    log.info(f"Number of areas : {nareas}")
    cla_zone = params_conf['cla_area'][:]

    recomb = 'off'
    # dict_bilan = {}

    if params_conf['bilan'] == 'on' and recomb == 'off':

        log.info("Bilan on and recomb off")
        # *********** repartition dates sur processeurs ***********
        for numvar, cvar in enumerate(cla_vars):
            log.info('')
            log.info("Bilan on")
            log.info(f"Variable: {cvar}")
            log.info('')
            # *************** Listing fichiers CLASS4 ***************
            ind_reg = 0
            ind_empty = 0
            cla_cl4files = []

            for d, cdate in enumerate(params_conf['cla_dates']):
                if params_conf['cexp'] == 'BIO':
                    global_path = (f"{params_conf['prefix']}_{cdate}_"
                                   f"{params_conf['config_obs']}_"
                                   f"{params_conf['config_model']}")
                    variable_name = cvar
                    log.debug(f'{global_path=}')
                    log.debug(f'{variable_name=}')
                else:
                    global_path = (f"{params_conf['prefix']}_{cdate}_"
                                   f"{params_conf['config_model']}_"
                                   f"{params_conf['cgrid']}")
                    if cvar in ['PSAL', 'TEMP']:
                        variable_name = "profile"
                    elif cvar in ['UVEL', 'VVEL']:
                        variable_name = "currents"
                    elif cvar in ['UVEL_filtr', 'VVEL_filtr']:
                        variable_name = "currents-filtr"
                    else:
                        variable_name = cvar
                cl_file = f"{global_path}_{variable_name}.nc"
                cla_filechck = glob.glob(f"{params_conf['dirNCin']}{cl_file}")
                if len(cla_filechck) != 1:
                    continue
                cla_cl4files.append(cla_filechck[0])
            if len(cla_cl4files) == 0:
                log.info("Missing files main")
                log.info(f"{params_conf['dirNCin']}{cl_file}")
                continue
            else:
                log.debug(cla_cl4files)
            list_variables = ['SST', 'SLA', 'aice',
                              'UVEL', 'VVEL', 'UVEL_filtr',
                              'VVEL_filtr']
            if params_conf['cexp'] == 'BIO' or cvar in list_variables:
                tab_prof = np.array([-0.5, 0.5])
            else:
                tab_prof = np.array(rla_layers)
            dict_inputs = cl4_reader.cfg_ltime(cla_cl4files[0],
                                               params_conf['cexp'],
                                               cvar)

            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            #         SELECTION OF GRID POINTS CONTAINED IN EACH BASIN
            # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

            area_mask = None

            dict_var = {}
            dict_var[cvar] = {}
            dict_var[cvar]['depth_obs'] = {}
            for name_ech in dict_inputs['lead_time']:
                dict_var[cvar][name_ech] = {}
            dict_var[cvar]['longitude'] = {}
            dict_var[cvar]['latitude'] = {}

            if 'climatology' not in dict_inputs['lead_time']:
                log.info(f'clim is missing {cl_file}')
                dict_var[cvar]['climatology'] = {}

            ini_var = True
            nb_regions = len(cla_zone)
            if params_conf['ll_arc']:
                min_lat = np.nanmin(rla_latmask)
            if params_conf['ll_ant']:
                min_lat = np.nanmax(rla_latmask)
            for ar, area_mask in enumerate(cla_zone):
                #print(f'area = {ar} {tracemalloc.get_traced_memory()}')
                meminfo = psutil.Process().memory_info().rss / 2**20
                log.info(f"RSS memory information init : {meminfo}")
                area_m = np.where(
                        np.array(params_conf['cla_area']) == area_mask)[0][0]

                if params_conf['CMEMS_area'] is True:
                    rla_maskvalues = np.unique(rla_mask[area_m, :, :])
                    rla_maskvalues = np.delete(
                            rla_maskvalues, np.where(rla_maskvalues == 0))

                stat_bilan = np.nan*np.zeros((dict_inputs['yout'],
                                              len(tab_prof) - 1,
                                              len(params_conf['cla_metricname'])))
                if ll_skill:
                    stat_PSS_skill = np.nan*np.zeros((5, len(tab_prof) - 1))
                    stat_CSS_skill = np.nan*np.zeros((5, len(tab_prof) - 1))
                if params_conf['CMEMS_area'] is False:
                    maskbox = rla_mask
                    maskval = rla_maskvalues[area_m]
                else:
                    maskbox = rla_mask[area_m, :, :]
                    maskval = rla_maskvalues[0]

                meminfo = psutil.Process().memory_info().rss / 2**20
                log.info(f"RSS memory information mask : {meminfo}")
                # **********************  Box definition  **********************

                ll_shift = False
                if area_mask != 'GLO':
                    i, j = np.where(maskbox == maskval)
                    boxlonmin = np.nanmin(rla_lonmask_nan[i, j])
                    boxlonmax = np.nanmax(rla_lonmask_nan[i, j])

                    # ~ Test the min/max value of the box and
                    #           shift in 0/360 if necessary ~

                    if boxlonmin < 0 and boxlonmax > 0:
                        if boxlonmax > 179.9:

                            # ~~~~~~~~ Shift 0-360 ~~~~~~~~~~~~~~~~~~~

                            rla_lonmask_nan_shift = np.where(rla_lonmask_nan < 0,
                                                             rla_lonmask_nan + 360,
                                                             rla_lonmask_nan)
                            rla_lonmask_tmp = rla_lonmask_nan_shift
                            ll_shift = True
                        else:
                            rla_lonmask_tmp = rla_lonmask_nan
                    else:
                        rla_lonmask_tmp = rla_lonmask_nan
                    boxlonmin = np.nanmin(rla_lonmask_tmp[i, j])
                    boxlonmax = np.nanmax(rla_lonmask_tmp[i, j])
                    boxlatmin = np.nanmin(rla_latmask[i, j])
                    boxlatmax = np.nanmax(rla_latmask[i, j])

                ilayer = 0
                dict = {}
                dict[area_mask] = {}
                for depthmin, depthmax in zip(tab_prof[:-1], tab_prof[1:]):

                    OBS = []
                    CLIM = []
                    BEST = []
                    FCST = []
                    PERS = []
                    dict_inputs['depthmin'] = depthmin
                    dict_inputs['depthmax'] = depthmax
                    log.debug(f"DEPTH: {depthmin}-{depthmax} m")
                    meminfo = psutil.Process().memory_info().rss / 2**20
                    log.info(f"RSS memory information mask depth : {meminfo}")

                    for num_date, cl_cl4file in enumerate(cla_cl4files):
                        # ************  add observation positions  ***************
                        if ilayer == 0 and ini_var is True:
                            dict_var = cl4_reader.read_and_store_inputfiles(
                                    dict_inputs['lead_time'],
                                    cvar,
                                    params_conf['cexp'],
                                    num_date,
                                    cl_cl4file,
                                    dict_var,
                                    params_conf['ll_arc'],
                                    params_conf['ll_ant'],
                                    ll_shift,
                                    rla_latmask,
                                    log,
                                    logger=log.getEffectiveLevel())
                            meminfo = psutil.Process().memory_info().rss / 2**20
                            log.info(f"RSS memory information .read_and_store : {meminfo}")

                        if ilayer == 0:
                            iobs = []
                            list_basin = ['basin', 'box', 'basin_pol']
                            if params_conf['fmt_mask'] in list_basin:
                                region = re.sub(' ', '_',
                                                params_conf['area_name'][ar])
                            else:
                                region = "region_"+str(ar)
                            log.debug(f"{region=}")
                            if region == 'Full_Domain':
                                iobs = np.arange(
                                    len(dict_var[cvar]['latitude'][str(num_date)]))
                            else:
                                rla_lonobs_tmp = \
                                    dict_var[cvar]['longitude'][str(num_date)]
                                rla_latobs = \
                                    dict_var[cvar]['latitude'][str(num_date)]
                                iobs = geomlib.search_points(
                                        params_conf['fmt_mask'],
                                        maskbox,
                                        maskval,
                                        rla_lonobs_tmp,
                                        rla_latobs,
                                        rla_lonmask_nan,
                                        rla_latmask,
                                        region,
                                        table_hull,
                                        logger=log.getEffectiveLevel())
                                if len(iobs) == 0:
                                    ind_empty += 1

                            dict[area_mask][str(num_date)] = iobs

                        else:
                            iobs = dict[area_mask][str(num_date)]
                        meminfo = psutil.Process().memory_info().rss / 2**20
                        log.info(f"RSS memory information before compute stats : {meminfo}")
                        if np.size(iobs) <= 1:
                            no_obs = True
                            log.info(f'Missing obs in that region {num_date}')
                            continue
                        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                        #                       COMPUTE STATS
                        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

                        # ***************  Compute Stats at each lead time ********
                        OBS, CLIM, BEST, FCST, PERS = \
                            stats.compute_stats_and_extend(
                                        dict_inputs, dict_var,
                                        dict,
                                        cvar,
                                        num_date,
                                        area_mask,
                                        OBS,
                                        CLIM,
                                        BEST,
                                        FCST,
                                        PERS,
                                        log,
                                        logger=log.getEffectiveLevel(),
                                        filename=cl_cl4file
                                        )
                        meminfo = psutil.Process().memory_info().rss / 2**20
                        log.info(f"RSS memory information after compute stats and extend : {meminfo}")
                    if np.size(OBS) != 0:
                        if params_conf['cexp'] == 'PHYS' and ll_skill:
                            stat_bilan, stat_PSS_skill, stat_CSS_skill = \
                                    stats.compute_stats_bilan_skill(dict_inputs,
                                                                    stat_bilan,
                                                                    stat_PSS_skill,
                                                                    stat_CSS_skill,
                                                                    ilayer,
                                                                    OBS,
                                                                    BEST,
                                                                    FCST,
                                                                    PERS,
                                                                    CLIM,
                                                                    log)
                        elif params_conf['cexp'] == 'PHYS' and not ll_skill:
                            stat_bilan = \
                                    stats.compute_stats_bilan(
                                            dict_inputs,
                                            stat_bilan,
                                            ilayer,
                                            OBS,
                                            BEST,
                                            FCST,
                                            PERS,
                                            CLIM,
                                            log,
                                            logger=log.getEffectiveLevel(),
                                            filename=cl_cl4file
                                            )
                        else:
                            meminfo = psutil.Process().memory_info().rss / 2**20
                            log.info(f"RSS memory information before stats bilan : {meminfo}")
                            stat_bilan = \
                                    stats.compute_stats_bilan(
                                            dict_inputs,
                                            stat_bilan,
                                            ilayer,
                                            OBS,
                                            BEST,
                                            FCST,
                                            PERS,
                                            CLIM,
                                            log,
                                            logger=log.getEffectiveLevel(),
                                            filename=cl_cl4file
                                            )
                            meminfo = psutil.Process().memory_info().rss / 2**20
                            log.info(f"RSS memory information after stats bilan : {meminfo}")

                    ilayer += 1

                ini_var = False
                nbval = set(stat_bilan[~np.isnan(stat_bilan)])
                if len(nbval) > 0:
                    w = np.where(np.isnan(stat_bilan) is True)
                    stat_bilan[w] = params_conf['missing_value']
                    w = np.where(stat_bilan > params_conf['missing_value'])
                    stat_bilan[w] = params_conf['missing_value']
                    if params_conf['cexp'] == 'PHYS' and ll_skill:
                        w = np.where(np.isnan(stat_PSS_skill) is True)
                        stat_PSS_skill[w] = params_conf['missing_value']
                        w = np.where(stat_PSS_skill > params_conf['missing_value'])
                        stat_PSS_skill[w] = params_conf['missing_value']
                        w = np.where(np.isnan(stat_CSS_skill) is True)
                        stat_CSS_skill[w] = params_conf['missing_value']
                        w = np.where(stat_CSS_skill > params_conf['missing_value'])
                        stat_CSS_skill[w] = params_conf['missing_value']
                        global_path_skill = (f"{params_conf['dirout']}TMP_"
                                             f"{params_conf['cla_dates'][0]}_"
                                             f"{params_conf['cla_dates'][-1]}/")

                        cl_FileName_bilan_skill = \
                            (f"glob_mean_quality_stats_{cvar}_"
                             f"{area_mask}_{params_conf['cl_start_date']}_"
                             f"{params_conf['cl_end_date']}_skill.nc")
                        cl_resultsFile_bilan_skill = \
                            f"{global_path_skill}{cl_FileName_bilan_skill}"

                    if 'climatology' not in dict_inputs['lead_time']:
                        leadtime = np.chararray(len(dict_inputs['lead_time'])+1,
                                                itemsize=14)
                        for lead in range(len(dict_inputs['lead_time'])):
                            leadtime[lead] = str(dict_inputs['lead_time'][lead])
                        leadtime[lead+1] = "climatology"
                    else:
                        leadtime = np.chararray(len(dict_inputs['lead_time']),
                                                itemsize=14)
                        for lead in range(len(dict_inputs['lead_time'])):
                            leadtime[lead] = str(dict_inputs['lead_time'][lead])
                    if 'observation' in leadtime:
                        leadtime = leadtime[1:]

                    cl_resultsFileName_bilan = (f"glob_mean_quality_stats_{cvar}_"
                                                f"{area_mask}_"
                                                f"{params_conf['cl_start_date']}_"
                                                f"{params_conf['cl_end_date']}.nc")
                    cl_resultsFileName_bilan_p = re.sub('.nc',
                                                        '.p',
                                                        cl_resultsFileName_bilan)
                    global_path_bilan = (f"{params_conf['dirout']}TMP_"
                                         f"{params_conf['cla_dates'][0]}_"
                                         f"{params_conf['cla_dates'][-1]}/")
                    cl_resultsFile_bilan = (f"{global_path_bilan}"
                                            f"{cl_resultsFileName_bilan}")
                    cl_resultsFile_bilan_p = (f"{global_path_bilan}"
                                              f"{cl_resultsFileName_bilan_p}")

                    if np.size(stat_bilan[0, :, 0]) > 1:
                        with open(cl_resultsFile_bilan_p, 'wb') as f:
                            pickle.dump(stat_bilan, f, pickle.HIGHEST_PROTOCOL)
                        log.debug(f"Feed dict_bilan : {cvar}{ area_mask}"
                                  f"{np.shape(stat_bilan)}")
                        meminfo = psutil.Process().memory_info().rss / 2**20
                        log.info(f"RSS memory info after dumping pickle file : {meminfo}")
                        if params_conf['cexp'] == 'PHYS' and ll_skill:
                            log.debug(f"Write file {cl_resultsFile_bilan_skill}")
                            writer_stat().write_glob_files_area_skill(
                                    cl_resultsFile_bilan_skill,
                                    rla_layers,
                                    stat_PSS_skill,
                                    stat_CSS_skill,
                                    params_conf
                                    )
                            del stat_PSS_skill, stat_CSS_skill
                            log.debug('Write skill')
                        del stat_bilan
                    else:
                        log.debug('Write Bilan File')
                        if ll_pickle:
                            with open(cl_resultsFile_bilan_p, 'wb') as f:
                                pickle.dump(stat_bilan, f, pickle.HIGHEST_PROTOCOL)
                        else:
                            writer_stat().write_glob_files_area(
                                    cl_resultsFile_bilan,
                                    params_conf['cla_metricname'],
                                    dict_inputs['rla_forecast'],
                                    rla_surface,
                                    stat_bilan,
                                    leadtime,
                                    params_conf,
                                    logger=log.getEffectiveLevel())
                        if params_conf['cexp'] == 'PHYS' and ll_skill:
                            writer_stat().write_glob_files_area_skill(
                                    cl_resultsFile_bilan_skill,
                                    rla_surface,
                                    stat_PSS_skill,
                                    stat_CSS_skill,
                                    params_conf
                                    )
                            del stat_PSS_skill, stat_CSS_skill
                            log.debug('Write skill')
                        log.debug(f"--- Feed dict_bilan zones: {area_mask}")
                        del stat_bilan
                else:
                    ind_reg += 1
                    log.info(f"Nbval is null for region {region} {ind_reg}/{nb_regions} {ind_empty}")
                    log.info(f"--------------------------------------------------")
                del dict

            gc.collect()
            del dict_var

        recomb = 'on'


    if params_conf['bilan'] == 'on':

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        #                     SAVE RESULTS IN A SINGLE FILE
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        log.info("Bilan on => save results")
        if ll_pickle:
            writer_stat().write_stats_BOX_dict(params_conf,
                                               cla_vars,
                                               rla_layers,
                                               rla_surface,
                                               rla_maskvalues,
                                               dict_inputs['rla_forecast'],
                                               leadtime)
        else:
            writer_stat().write_stats_BOX(params_conf,
                                          cla_vars,
                                          rla_layers,
                                          rla_surface,
                                          rla_maskvalues)

        if params_conf['cexp'] == 'PHYS' and ll_skill:
            log.info('Write global skill')
            writer_stat().write_stats_BOX_skill(params_conf,
                                                cla_vars,
                                                rla_layers,
                                                rla_surface,
                                                rla_maskvalues)
        end = timer()
        log.info(' ')
        log.info(f"~ Running time for global stats:{(end - start)} seconds ~")
        log.info(' ')
        log.info(' ')
        log.info('***********************************************************')
        log.info('      END OF GLOBAL STATS COMPUTATION                      ')
        log.info('***********************************************************')
        # Cleanup
        for file in glob.glob(params_conf['dirout']+'TMP/*'):
            os.remove(file)
        path_out = (f"{params_conf['dirout']}TMP_{params_conf['cla_dates'][0]}_"
                    f"{params_conf['cla_dates'][-1]}/*")
        for file in glob.glob(path_out):
            os.remove(file)
# Set the level of logger (log_level = 2)
# Run the main code
if __name__ == "__main__":
    main()
