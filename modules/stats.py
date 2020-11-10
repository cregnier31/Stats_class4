import os
import sys
import numpy as np
import supobs
from loader_post import stat_mod_obs, stat_mod_glob, stat_obs_glob
import arithm

__version__ = 0.1
__date__  = "February 2019"
__author__ = "C.SZCZYPTA"



def compute_stats_and_extend(dict_inputs, dict_var, dict, cvar,
                             num_date, area_mask, OBS, CLIM, BEST, FCST, PERS):
    """
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                 COMPUTE STATS DIFFERENT LEAD TIME
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Arguments
    --------------------
    dict_inputs: input dictionnary
    dict_var: dictionnary with concatenated arrays
    dict:
    cvar: input variable
    num_date: date index
    area_mask: mask index
    Returns
    --------------------
    OBS: extended array for observations
    BEST: extended array for best estimates
    CLIM: extended array for climatology
    FCST: extended array for forecasts
    PERS: extended array for persistency
    --------------------
    """

    lead_time = dict_inputs['lead_time']
    nb_fcst = dict_inputs['nb_fcst']
    depthmin = dict_inputs['depthmin']
    depthmax = dict_inputs['depthmax']
    iobs = dict[area_mask][str(num_date)]

    for time in lead_time:
        rla_observation_var = dict_var[cvar]['observation'][str(num_date)]
        if len(np.shape(rla_observation_var)) == 2:
            rla_obs = rla_observation_var[iobs, :]
            if 'climatology' in lead_time:
                rla_climatology_var = dict_var[cvar]['climatology'][str(
                    num_date)]
                rla_clim = rla_climatology_var[iobs, :]
            else:
                rla_clim = np.nan*np.zeros((np.size(rla_obs[:, 0]), 1))
        else:
            rla_obs = rla_observation_var[iobs]
            if 'climatology' in lead_time:
                rla_climatology_var = dict_var[cvar]['climatology'][str(
                    num_date)]
                rla_clim = rla_climatology_var[iobs]
            else:
                rla_clim = np.nan*np.zeros((np.shape(rla_obs), 1))
        if time == 'best_estimate':
            rla_best_estimate_var = dict_var[cvar]['best_estimate'][str(
                num_date)]
            rla_depthobs = dict_var[cvar]['depth_obs'][str(num_date)]
            if len(np.shape(rla_best_estimate_var)) == 2:
                rla_var = rla_best_estimate_var[iobs, :]
            else:
                rla_var = rla_best_estimate_var[iobs]

            val_box_depth, obs_box_depth, clim_box_depth =\
                supobs.Statslib.extract_CL4var(rla_var, rla_obs, rla_clim,
                                               rla_depthobs[iobs, :], depthmin, depthmax)
            OBS.extend(obs_box_depth)
            CLIM.extend(clim_box_depth)
            BEST.extend(val_box_depth)
        if time == 'forecast':
            rla_forecast_var = dict_var[cvar]['forecast'][str(num_date)]
            if nb_fcst == 1:
                fmax = 1
            else:
                fmax = nb_fcst//2
            for numF in range(0, fmax):
                FCT = []
                if nb_fcst == 1 and len(np.shape(rla_forecast_var)) == 2:
                    rla_var = rla_forecast_var[iobs, :]
                elif nb_fcst == 1 and len(np.shape(rla_forecast_var)) == 1:
                    rla_var = rla_forecast_var[iobs]
                elif nb_fcst > 1 and len(np.shape(rla_forecast_var)) == 2:
                    rla_var = rla_forecast_var[iobs, numF*2]
                else:
                    rla_var = rla_forecast_var[iobs, numF*2, :]
                val_box_depth, obs_box_depth, clim_box_depth =\
                    supobs.Statslib.extract_CL4var(rla_var, rla_obs, rla_clim,
                                                   rla_depthobs[iobs, :], depthmin, depthmax)
                FCT.extend(val_box_depth)
                if numF == 0:
                    FCST_tmp = np.nan*np.zeros((len(np.array(FCT)), fmax))
                FCST_tmp[:, numF] = np.array(FCT)
            FCST.extend(FCST_tmp)
        if time == 'persistence':
            rla_persistence_var = dict_var[cvar]['persistence'][str(
                num_date)]
            if nb_fcst == 1:
                fmax = 1
            else:
                fmax = nb_fcst//2
            for numF in range(0, fmax):
                PER = []
                if nb_fcst == 1 and len(np.shape(rla_persistence_var)) == 2:
                    rla_var = rla_persistence_var[iobs, :]
                elif nb_fcst == 1 and len(np.shape(rla_persistence_var)) == 1:
                    rla_var = rla_persistence_var[iobs]
                elif nb_fcst > 1 and len(np.shape(rla_persistence_var)) == 2:
                    rla_var = rla_persistence_var[iobs, numF*2]
                else:
                    rla_var = rla_persistence_var[iobs, numF*2, :]
                val_box_depth, obs_box_depth, clim_box_depth =\
                    supobs.Statslib.extract_CL4var(rla_var, rla_obs,
                                                   rla_clim, rla_depthobs[iobs, :], depthmin, depthmax)
                PER.extend(val_box_depth)
                if numF == 0:
                    PERS_tmp = np.nan*np.zeros((len(np.array(PER)), fmax))
                PERS_tmp[:, numF] = np.array(PER)
            PERS.extend(PERS_tmp)

    return OBS, CLIM, BEST, FCST, PERS


def compute_stats_skill(lead_time, nb_fcst, iobs, dict_inputs, stat_tmp, \
                        stat_PSS_skill, stat_CSS_skill, amask, yout, log):
    """
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #         COMPUTE STATS FOR EACH BASIN AT DIFFERENT LEAD TIME
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Arguments
    --------------------
    lead_time: input lead time
    iobs: selection of observations for an area
    dict_inputs: input arrays for computing statistics
    Returns
    stat_tmp:  array with all the statistics for each cell
    --------------------
    """
    ll_debug = False
    ll_persistence = False
    ll_forecast = False
    for time in lead_time:
        if len(np.shape(dict_inputs['obs'])) == 2:
            rla_obs = dict_inputs['obs'][iobs, :]
            if 'climatology' in lead_time:
                rla_clim = dict_inputs['clim'][iobs, :]
            else:
                nb_obs, nb_depths = np.shape(rla_obs)
                #rla_clim = np.nan*np.zeros((np.size(rla_obs[:, 0]), 1))
                rla_clim = np.nan*np.zeros((nb_obs, nb_depths))
        else:
            rla_obs = dict_inputs['obs'][iobs]
            if 'climatology' in lead_time:
                rla_clim = dict_inputs['clim'][iobs]
            else:
                rla_clim = np.nan*np.zeros((np.size(rla_obs)))

        if time == 'best_estimate':
            num_col = 0
            if len(np.shape(dict_inputs['best'])) == 2:
                rla_var = dict_inputs['best'][iobs, :]
            else:
                rla_var = dict_inputs['best'][iobs]
            rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                supobs.Statslib.statlayer_CL4var(rla_var,
                                                 rla_obs,
                                                 rla_clim,
                                                 dict_inputs['rla_depthobs'][iobs, :],
                                                 dict_inputs['tab_profs'])
            if ll_debug:
                print(('RMSE {}'.format(rla_rmse)))
            stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                    rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                    rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

            del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        elif time == 'forecast':
            ll_forecast = True
            if nb_fcst == 1:
                fmax = 1
            else:
                fmax = nb_fcst//2
            for numF in range(0, fmax):
                if nb_fcst == 1 and len(np.shape(dict_inputs['frcst'])) == 2:
                    rla_var = dict_inputs['frcst'][iobs, :]
                elif nb_fcst == 1 and len(np.shape(dict_inputs['frcst'])) == 1:
                    rla_var = dict_inputs['frcst'][iobs]
                elif nb_fcst > 1 and len(np.shape(dict_inputs['frcst'])) == 2:
                    rla_var = dict_inputs['frcst'][iobs, numF*2]
                else:
                    rla_var = dict_inputs['frcst'][iobs, numF*2, :]

                rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                    supobs.Statslib.statlayer_CL4var(rla_var,
                                                     rla_obs,
                                                     rla_clim,
                                                     dict_inputs['rla_depthobs'][iobs, :],
                                                     dict_inputs['tab_profs'])

                stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                        rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                        rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

                del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        elif time == 'persistence':
            ll_persistence = True
            if nb_fcst == 1:
                fmax = 1
            else:
                fmax = nb_fcst//2
            for numF in range(0, fmax):
                if nb_fcst == 1 and len(np.shape(dict_inputs['pers'])) == 2:
                    rla_var = dict_inputs['pers'][iobs, :]
                elif nb_fcst == 1 and len(np.shape(dict_inputs['pers'])) == 1:
                    rla_var = dict_inputs['pers'][iobs]
                elif nb_fcst > 1 and len(np.shape(dict_inputs['pers'])) == 2:
                    rla_var = dict_inputs['pers'][iobs, numF*2]
                else:
                    rla_var = dict_inputs['pers'][iobs, numF*2, :]

                rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                    supobs.Statslib.statlayer_CL4var(rla_var,
                                                     rla_obs,
                                                     rla_clim,
                                                     dict_inputs['rla_depthobs'][iobs, :],
                                                     dict_inputs['tab_profs'])

                stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                        rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                        rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

                del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        elif time == 'climatology':
            if len(np.shape(dict_inputs['clim'])) == 2:
                rla_var = dict_inputs['clim'][iobs, :]
            else:
                rla_var = dict_inputs['clim'][iobs]

            rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                supobs.Statslib.statlayer_CL4var(rla_var,
                                                 rla_obs,
                                                 rla_clim,
                                                 dict_inputs['rla_depthobs'][iobs, :],
                                                 dict_inputs['tab_profs'])

            stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                    rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                    rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

            if abs(np.nanmax(rla_rmse)) > 100.:
                #log.info('CLIMATOLOGY')
                #log.info('Minimum obs : %f' %(np.nanmin(rla_mean_obs)))
                #log.info('Maximum obs : %f' %(np.nanmax(rla_mean_obs)))
                #log.info('Minimum rmse : %f ' %(np.nanmin(rla_rmse)))
                #log.info('Maximum rmse: %f ' %(np.nanmax(rla_rmse)))
                log.error("Probleme with the climatology")
                sys.exit(1)

            del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        else:
            continue
    if ll_forecast and ll_persistence:
        ## Compute skill score
        ## Skill for 1D 3D 5D 7D 9D
        for nbFcst in range(0, fmax):
            stat_PSS_skill[nbFcst, :, amask] =  1  - (np.sqrt(stat_tmp[nbFcst+1, :, 5, amask]) / np.sqrt(stat_tmp[nbFcst+fmax+1, :, 5, amask]))
            stat_CSS_skill[nbFcst, :, amask] =  1  - (np.sqrt(stat_tmp[nbFcst+1, :, 5, amask]) / np.sqrt(stat_tmp[2*fmax+1, :, 5, amask]))
    else:
        print ('Forecast or persistence missing')
        stat_PSS_skill[:,:,:] = np.nan
        stat_CSS_skill[:,:,:] = np.nan

    return stat_tmp, stat_PSS_skill, stat_CSS_skill


def compute_stats(lead_time, nb_fcst, iobs, dict_inputs, stat_tmp, amask, yout):
    """
     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    #         COMPUTE STATS FOR EACH BASIN AT DIFFERENT LEAD TIME
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Arguments
    --------------------
    lead_time: input lead time
    iobs: selection of observations for an area
    dict_inputs: input arrays for computing statistics
    Returns
    stat_tmp:  array with all the statistics for each cell
    --------------------
    """
    ll_debug = False

    for time in lead_time:
        if len(np.shape(dict_inputs['obs'])) == 2:
            rla_obs = dict_inputs['obs'][iobs, :]
            if 'climatology' in lead_time:
                rla_clim = dict_inputs['clim'][iobs, :]
            else:
                rla_clim = np.nan*np.zeros((np.size(rla_obs[:, 0]), 1))
        else:
            rla_obs = dict_inputs['obs'][iobs]
            if 'climatology' in lead_time:
                rla_clim = dict_inputs['clim'][iobs]
            else:
                rla_clim = np.nan*np.zeros((np.size(rla_obs)))

        if time == 'best_estimate':
            num_col = 0
            if len(np.shape(dict_inputs['best'])) == 2:
                rla_var = dict_inputs['best'][iobs, :]
            else:
                rla_var = dict_inputs['best'][iobs]
            rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                supobs.Statslib.statlayer_CL4var(rla_var,
                                                 rla_obs,
                                                 rla_clim,
                                                 dict_inputs['rla_depthobs'][iobs, :],
                                                 dict_inputs['tab_profs'])

            if ll_debug:
                print (rla_rmse)
                print("-----------------")

            stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                    rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                    rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

            del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        elif time == 'forecast':
            if nb_fcst == 1:
                fmax = 1
            else:
                fmax = nb_fcst//2
            for numF in range(0, fmax):
                if nb_fcst == 1 and len(np.shape(dict_inputs['frcst'])) == 2:
                    rla_var = dict_inputs['frcst'][iobs, :]
                elif nb_fcst == 1 and len(np.shape(dict_inputs['frcst'])) == 1:
                    rla_var = dict_inputs['frcst'][iobs]
                elif nb_fcst > 1 and len(np.shape(dict_inputs['frcst'])) == 2:
                    rla_var = dict_inputs['frcst'][iobs, numF*2]
                else:
                    rla_var = dict_inputs['frcst'][iobs, numF*2, :]

                rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                    supobs.Statslib.statlayer_CL4var(rla_var,
                                                     rla_obs,
                                                     rla_clim,
                                                     dict_inputs['rla_depthobs'][iobs, :],
                                                     dict_inputs['tab_profs'])

                stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                        rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                        rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

                del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        elif time == 'persistence':
            if nb_fcst == 1:
                fmax = 1
            else:
                fmax = nb_fcst//2
            for numF in range(0, fmax):
                if nb_fcst == 1 and len(np.shape(dict_inputs['pers'])) == 2:
                    rla_var = dict_inputs['pers'][iobs, :]
                elif nb_fcst == 1 and len(np.shape(dict_inputs['pers'])) == 1:
                    rla_var = dict_inputs['pers'][iobs]
                elif nb_fcst > 1 and len(np.shape(dict_inputs['pers'])) == 2:
                    rla_var = dict_inputs['pers'][iobs, numF*2]
                else:
                    rla_var = dict_inputs['pers'][iobs, numF*2, :]

                rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                    supobs.Statslib.statlayer_CL4var(rla_var,
                                                     rla_obs,
                                                     rla_clim,
                                                     dict_inputs['rla_depthobs'][iobs, :],
                                                     dict_inputs['tab_profs'])

                stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                        rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                        rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

                del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        elif time == 'climatology':
            if len(np.shape(dict_inputs['clim'])) == 2:
                rla_var = dict_inputs['clim'][iobs, :]
            else:
                rla_var = dict_inputs['clim'][iobs]

            rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor, ila_nobs =\
                supobs.Statslib.statlayer_CL4var(rla_var,
                                                 rla_obs,
                                                 rla_clim,
                                                 dict_inputs['rla_depthobs'][iobs, :],
                                                 dict_inputs['tab_profs'])

            stat_tmp, num_col = stat_mod_obs(stat_tmp, num_col, amask, ila_nobs,
                                                    rla_mean_obs, rla_rms_obs, rla_mean_prod,
                                                    rla_rms_prod, rla_rmse, rla_cor, dict_inputs['tab_profs'], yout)

            del ila_nobs, rla_mean_obs, rla_rms_obs, rla_mean_prod, rla_rms_prod, rla_rmse, rla_cor

        else:
            continue

    return stat_tmp

def compute_stats_bilan_skill(dict_inputs, stat_bilan, stat_PSS_skill, stat_CSS_skill, ilayer, OBS,
                        BEST, FCST, PERS, CLIM, log):
    """
            COMPUTE GLOBAL STATS DIFFERENT LEAD TIME

    """
    OBS = np.array(OBS)
    PERS = np.array(PERS)
    FCST = np.array(FCST)
    CLIM = np.array(CLIM)
    BEST = np.array(BEST)
    lead_time = dict_inputs['lead_time']
    nb_fcst = dict_inputs['nb_fcst']
    for time in lead_time:
        if time == 'observation':
            if (np.size(np.where(~ np.isnan(OBS))[0])) > 0:
                rla_mean = arithm.nanmean(OBS)
                rla_rms = np.sqrt(arithm.nanms(OBS))
            else:
                rla_mean = np.nan
                rla_rms = np.nan
            stat_bilan = stat_obs_glob(
                stat_bilan, dict_inputs['yout'], ilayer, rla_mean, rla_rms)
            rla_mean_obs = rla_mean
        if time == 'best_estimate':
            num_col = 0
            if (np.size(np.where(~ np.isnan(BEST))[0])) > 0 and ~ np.isnan(np.array(rla_mean_obs)):
                rla_mean = arithm.nanmean(BEST)
                rla_rms = np.sqrt(arithm.nanms(BEST))
                ila_nobs = np.size(np.where(~ np.isnan(BEST[:]))[0])
                rla_rmse = np.sqrt(arithm.nanmse(BEST, OBS))
                rla_cor = arithm.nanpearson(BEST-CLIM, OBS-CLIM)
                #rla_meandiff = arithm.nansummd(BEST, OBS)
                #rla_rmsdiff = arithm.nansumse(BEST, OBS)
                #rl_val1 = rla_meandiff/ila_nobs
                #rl_val2 = rla_mean_obs-rla_mean
                #diff = rl_val2 - rl_val1
                #if abs(diff) > 0.1:
                #    log.error("Probleme")
                #    log.info(rl_val1, rl_val2)
                #    sys.exit(1)
            else:
                rla_mean = np.nan
                rla_rms = np.nan
                ila_nobs = np.nan
                rla_rmse = np.nan
                rla_cor = np.nan
                #rla_meandiff = np.nan
                #rla_rmsdiff = np.nan
            stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                        ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                        rla_cor)#, rla_meandiff, rla_rmsdiff)

        if time == 'forecast':
            nfcst = nb_fcst//2
            for numF in range(0, nfcst):
                if len(np.shape(FCST)) < 2:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    #rla_meandiff = np.nan
                    #rla_rmsdiff = np.nan
                elif (np.size(np.where(~ np.isnan(FCST[:, numF]))[0])) > 0 and ~ np.isnan(np.array(rla_mean_obs)):
                    rla_mean = arithm.nanmean(FCST[:, numF])
                    rla_rms = np.sqrt(arithm.nanms(FCST[:, numF]))
                    ila_nobs = np.size(np.where(~ np.isnan(FCST[:, numF]))[0])
                    rla_rmse = np.sqrt(arithm.nanmse(FCST[:, numF], OBS))
                    rla_cor = arithm.nanpearson(FCST[:, numF]-CLIM, OBS-CLIM)
                    #rla_meandiff = arithm.nansummd(FCST[:, numF], OBS)
                    #rla_rmsdiff = arithm.nansumse(FCST[:, numF], OBS)
                else:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    #rla_meandiff = np.nan
                    #rla_rmsdiff = np.nan
                stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                            ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                            rla_cor)#, rla_meandiff, rla_rmsdiff)
        if time == 'persistence':
            nfcst = nb_fcst//2
            for numF in range(0, nfcst):
                if len(np.shape(PERS)) < 2:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    #rla_meandiff = np.nan
                    #rla_rmsdiff = np.nan
                elif (np.size(np.where(~ np.isnan(PERS[:, numF]))[0])) > 0 and ~ np.isnan(np.array(rla_mean_obs)):
                    rla_mean = arithm.nanmean(PERS[:, numF])
                    rla_rms = np.sqrt(arithm.nanms(PERS[:, numF]))
                    ila_nobs = np.size(np.where(~ np.isnan(PERS[:, numF]))[0])
                    rla_rmse = np.sqrt(arithm.nanmse(PERS[:, numF], OBS))
                    rla_cor = arithm.nanpearson(PERS[:, numF]-CLIM, OBS-CLIM)
                    #rla_meandiff = arithm.nansummd(PERS[:, numF], OBS)
                    #rla_rmsdiff = arithm.nansumse(PERS[:, numF], OBS)
                else:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    #rla_meandiff = np.nan
                    #rla_rmsdiff = np.nan
                stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                            ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                            rla_cor)#, rla_meandiff, rla_rmsdiff)
        if time == 'climatology':
            if (np.size(np.where(~ np.isnan(CLIM))[0])) > 0:
                rla_mean = arithm.nanmean(CLIM)
                rla_rms = np.sqrt(arithm.nanms(CLIM))
                ila_nobs = np.size(np.where(~ np.isnan(CLIM[:]))[0])
                rla_rmse = np.sqrt(arithm.nanmse(CLIM, OBS))
                rla_cor = arithm.nanpearson(CLIM-CLIM, OBS-CLIM)
                #rla_meandiff = arithm.nansummd(CLIM, OBS)
                #rla_rmsdiff = arithm.nansumse(CLIM, OBS)
            else:
                rla_mean = np.nan
                rla_rms = np.nan
                ila_nobs = np.nan
                rla_rmse = np.nan
                rla_cor = np.nan
                #rla_meandiff = np.nan
                #rla_rmsdiff = np.nan
            stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                        ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                        rla_cor)#, rla_meandiff, rla_rmsdiff)
    if 'climatology' not in lead_time:
        rla_mean = np.nan
        rla_rms = np.nan
        ila_nobs = np.nan
        rla_rmse = np.nan
        rla_cor = np.nan
        #rla_meandiff = np.nan
        #rla_rmsdiff = np.nan
        stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                    ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                    rla_cor)#, rla_meandiff, rla_rmsdiff)
    ## Compute skill 
    ## Skill for 1D 3D 5D 7D 9D
    for numF in range(0, nfcst):
        #stat_PSS_skill[numF, ilayer] =  1  - (np.sqrt(stat_bilan[numF+1, ilayer, 5]) / np.sqrt(stat_bilan[numF+6, ilayer, 5]))
        #stat_CSS_skill[numF, ilayer] =  1  - (np.sqrt(stat_bilan[numF+1, ilayer, 5]) / np.sqrt(stat_bilan[11, ilayer, 5]))
        stat_PSS_skill[numF, ilayer] =  1  - (np.sqrt(stat_bilan[numF+1, ilayer, 5]) / np.sqrt(stat_bilan[numF+nfcst+1, ilayer, 5]))
        stat_CSS_skill[numF, ilayer] =  1  - (np.sqrt(stat_bilan[numF+1, ilayer, 5]) / np.sqrt(stat_bilan[2*nfcst+1, ilayer, 5]))
    return stat_bilan, stat_PSS_skill, stat_CSS_skill


def compute_stats_bilan(dict_inputs, stat_bilan, ilayer, OBS,
                        BEST, FCST, PERS, CLIM, log):
    """
            COMPUTE GLOBAL STATS DIFFERENT LEAD TIME

    """
    OBS = np.array(OBS)
    PERS = np.array(PERS)
    FCST = np.array(FCST)
    CLIM = np.array(CLIM)
    BEST = np.array(BEST)
    lead_time = dict_inputs['lead_time']
    nb_fcst = dict_inputs['nb_fcst']

    for time in lead_time:
        if time == 'observation':
            if (np.size(np.where(~ np.isnan(OBS))[0])) > 0:
                rla_mean = arithm.nanmean(OBS)
                rla_rms = np.sqrt(arithm.nanms(OBS))
            else:
                rla_mean = np.nan
                rla_rms = np.nan
            stat_bilan = stat_obs_glob(
                stat_bilan, dict_inputs['yout'], ilayer, rla_mean, rla_rms)
            rla_mean_obs = rla_mean
        if time == 'best_estimate':
            num_col = 0
            if (np.size(np.where(~ np.isnan(BEST))[0])) > 0 and ~ np.isnan(np.array(rla_mean_obs)):
                rla_mean = arithm.nanmean(BEST)
                rla_rms = np.sqrt(arithm.nanms(BEST))
                ila_nobs = np.size(np.where(~ np.isnan(BEST[:]))[0])
                rla_rmse = np.sqrt(arithm.nanmse(BEST, OBS))
                rla_cor = arithm.nanpearson(BEST-CLIM, OBS-CLIM)
                rla_meandiff = arithm.nansummd(BEST, OBS)
                rla_rmsdiff = arithm.nansumse(BEST, OBS)
                rl_val1 = rla_meandiff/ila_nobs
                rl_val2 = rla_mean_obs-rla_mean
                diff = rl_val2 - rl_val1
                if abs(diff) > 0.1:
                    log.error("Probleme")
                    log.info(rl_val1, rl_val2)
                    sys.exit(1)
            else:
                rla_mean = np.nan
                rla_rms = np.nan
                ila_nobs = np.nan
                rla_rmse = np.nan
                rla_cor = np.nan
                rla_meandiff = np.nan
                rla_rmsdiff = np.nan

            log.info('HINDCAST')
            #log.info(np.nanmin(rla_mean), np.nanmin(rla_rmse), np.nanmax(rla_rmse))

            stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                        ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                        rla_cor)

        if time == 'forecast':
            nfcst = nb_fcst//2
            for numF in range(0, nfcst):
                if len(np.shape(FCST)) < 2:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    rla_meandiff = np.nan
                    rla_rmsdiff = np.nan
                elif (np.size(np.where(~ np.isnan(FCST[:, numF]))[0])) > 0 and ~ np.isnan(np.array(rla_mean_obs)):
                    rla_mean = arithm.nanmean(FCST[:, numF])
                    rla_rms = np.sqrt(arithm.nanms(FCST[:, numF]))
                    ila_nobs = np.size(np.where(~ np.isnan(FCST[:, numF]))[0])
                    rla_rmse = np.sqrt(arithm.nanmse(FCST[:, numF], OBS))
                    rla_cor = arithm.nanpearson(FCST[:, numF]-CLIM, OBS-CLIM)
                    rla_meandiff = arithm.nansummd(FCST[:, numF], OBS)
                    rla_rmsdiff = arithm.nansumse(FCST[:, numF], OBS)
                else:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    rla_meandiff = np.nan
                    rla_rmsdiff = np.nan
                stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                            ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                            rla_cor)
        if time == 'persistence':
            nfcst = nb_fcst//2
            for numF in range(0, nfcst):
                if len(np.shape(PERS)) < 2:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    rla_meandiff = np.nan
                    rla_rmsdiff = np.nan
                elif (np.size(np.where(~ np.isnan(PERS[:, numF]))[0])) > 0 and ~ np.isnan(np.array(rla_mean_obs)):
                    rla_mean = arithm.nanmean(PERS[:, numF])
                    rla_rms = np.sqrt(arithm.nanms(PERS[:, numF]))
                    ila_nobs = np.size(np.where(~ np.isnan(PERS[:, numF]))[0])
                    rla_rmse = np.sqrt(arithm.nanmse(PERS[:, numF], OBS))
                    rla_cor = arithm.nanpearson(PERS[:, numF]-CLIM, OBS-CLIM)
                    rla_meandiff = arithm.nansummd(PERS[:, numF], OBS)
                    rla_rmsdiff = arithm.nansumse(PERS[:, numF], OBS)
                else:
                    rla_mean = np.nan
                    rla_rms = np.nan
                    ila_nobs = np.nan
                    rla_rmse = np.nan
                    rla_cor = np.nan
                    rla_meandiff = np.nan
                    rla_rmsdiff = np.nan
                stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                            ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                            rla_cor)
                # TODO compute skill
        if time == 'climatology':
            if (np.size(np.where(~ np.isnan(CLIM))[0])) > 0:
                rla_mean = arithm.nanmean(CLIM)
                rla_rms = np.sqrt(arithm.nanms(CLIM))
                ila_nobs = np.size(np.where(~ np.isnan(CLIM[:]))[0])
                rla_rmse = np.sqrt(arithm.nanmse(CLIM, OBS))
                rla_cor = arithm.nanpearson(CLIM-CLIM, OBS-CLIM)
                rla_meandiff = arithm.nansummd(CLIM, OBS)
                rla_rmsdiff = arithm.nansumse(CLIM, OBS)
            else:
                rla_mean = np.nan
                rla_rms = np.nan
                ila_nobs = np.nan
                rla_rmse = np.nan
                rla_cor = np.nan
                rla_meandiff = np.nan
                rla_rmsdiff = np.nan

            #log.info('CLIMATOLOGY')
            #log.info(np.nanmin(rla_mean), np.nanmin(rla_rmse), np.nanmax(rla_rmse))

            stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                        ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                        rla_cor)
    if 'climatology' not in lead_time:
        rla_mean = np.nan
        rla_rms = np.nan
        ila_nobs = np.nan
        rla_rmse = np.nan
        rla_cor = np.nan
        rla_meandiff = np.nan
        rla_rmsdiff = np.nan
        stat_bilan, num_col = stat_mod_glob(stat_bilan, num_col, ilayer,
                                                    ila_nobs, rla_mean, rla_rms, rla_rmse,
                                                    rla_cor)

    return stat_bilan


