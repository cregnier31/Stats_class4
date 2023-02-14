# -*- coding: utf-8 -*-
"""
Created on Wed Nov 28 09:13:09 2017

@author: cszczypta
"""

#!/usr/bin/python
#========================================== 

import sys
import matplotlib
#matplotlib.use('TkAgg')
import matplotlib.dates as dates
import matplotlib.pyplot as plt
import numpy as np
from lib_pyt.filter.filters import medfilt
import pandas as pd

def fmtFig(area, name_ech, splot='single', nb_var=1):
    """
    Define the format and configuration of figure with subplot

    Parameters
    ----------
    area: Str - name of the considered area
    splot: Str - single or multi for a plot or a multiplot 
    """

    if splot == 'single':
        fig = plt.figure(figsize = (12,5))
        fig.subplots_adjust(left = 0.06, bottom = 0.14,
                            right = 0.927, top = 0.86, wspace = 0.12, hspace = 0.3)
    elif splot == 'multi' and nb_var == 4:
        fig = plt.figure(figsize = (12,13))
        fig.subplots_adjust(left = 0.06, bottom = 0.085,
                            right = 0.92, top = 0.92, wspace = 0.12, hspace = 0.3)
    elif splot == 'multi' and nb_var == 2:
        fig = plt.figure(figsize = (12,7))
        fig.subplots_adjust(left = 0.06, bottom = 0.14,
                            right = 0.92, top = 0.89, wspace = 0.12, hspace = 0.3)
    else:
        print ('************ config not found ************')
        sys.exit()

    plt.suptitle(area+' - '+name_ech,fontsize=15.5+nb_var,color='red')

    return fig, splot, nb_var


def plotStat(fig, ax_fig, dict, varname, area, system,
             ind_run, prof, datemin, datemax, leg, list_color,
             splot, nb_var, skill, list_fcst, med_filtr=False, window=5):
    """
    Plot the timeserie of RMSD, Bias and number of observations of the different systems

    Parameters
    ----------
    dict: float - Dictionnary which contains stats
    varname: str - Variable name
    area: str - Area name
    system: str - List of the different considered systems
    prof: str - Depth
    datemin, datemax: date - Limits of the time period
    leg: True/False - To know if the legend needs to be plotted or not
    list_color: str - Colors for the different curves
    """

    # ~~~~~~~~ Plot des time series ~~~~~~~~~~~
    list_system = ['PSY4', 'ENSMEAN', 'PSY3', 'FOAM', 'HYCOM_RTOFS',\
        'BLK', 'GIOPS', 'NERSC', 'CGOFS', 'CMCC', 'PSY4V3R1', 'GLO12V4','FOAM_ORCA12',
        'WED', 'THU', 'SUN', 'MON', 'TUE', 'DAY0', 'DAY1', 'DAY2', 'DAY3', 'DAY4', 'DAY5',
        'DAY6', 'DAY7', 'ALL']
    #list_system = ['GLO12V4']
    #list_system = ['PSY4','FOAM','HYCOM_RTOFS','BLK','GIOPS','NERSC','CMCC','PSY4V3R1']
    run_name = system
    len_run = 7
    list_metric_aice = ['PCI','PCW','PCT','BIAS']
    list_lead = list(dict[varname].keys())
    def search_lead(list_fcst, list_lead, ind_run):
        ind_tmp = ind_run
        dict_lead = {}

        for ind_lead, lead in enumerate(list_fcst):
            if ind_lead > 0:
                if ind_lead == 1:
                    ind_tmp = ind_tmp + ind_lead
                    if ind_tmp >= len(list_lead):
                         ind_tmp = ind_tmp - len(list_lead)
                else:
                    ind_tmp = ind_tmp + 2
                    if ind_tmp >= len(list_lead):
                        ind_tmp = ind_tmp - len(list_lead)
                        print(f'inside else {ind_tmp}{len(list_lead)}')
                print(f'Ind_lead > 0 Run {ind_lead} Work on {ind_tmp}: lead {lead}')
                print(f'ind_lead > 0 Run {ind_lead} Day involved {list_lead[ind_tmp]}')
            else:
                if ind_tmp < 0:
                    ind_tmp = ind_tmp + len_run
                print(f'Ind_lead = 0 Run {ind_lead} Work on {ind_tmp}: lead {lead} RUN IN {list_lead[ind_tmp]}')
            dict_lead[lead] = list_lead[ind_tmp]
        return dict_lead
    dict_lead = search_lead(list_fcst, list_lead, ind_run)
    for ind_lead, lead in enumerate(list_fcst):
        prod_name = dict_lead[lead]
        print(f'Run {run_name} Forecast {lead} Run involved {prod_name}')
        if 'time' not in dict[varname][prod_name][lead][area][prof]:
            continue
        if skill == 1:
            plt.plot(np.array(dict[varname][prod_name][lead][area][prof]['time']),
                     np.array(dict[varname][prod_name][lead][area][prof]['PSS']),
                     linewidth = 1.2, color = list_color[ind_lead], label = name_lab)
            plt.plot(np.array(dict[varname][prod_name][lead][area][prof]['time']),
                     np.array(dict[varname][prod_name][lead][area][prof]['CSS']),
                     linestyle = '--', linewidth = 1.2, color = list_color[ind_lead])
        else:
            ii = np.where(~np.isnan(np.array(dict[varname][prod_name][lead][area][prof]['rmsd'])))
            rms_tmp =  np.array(dict[varname][prod_name][lead][area][prof]['rmsd'])[ii]
            if  med_filtr:
                #print(f'Data filtered {window}')
                if len(rms_tmp > 0):
                    var_filtre1 = medfilt(rms_tmp[:], window)
                    data = pd.Series(var_filtre1)
                    rms_tmp = data.rolling(window, center=True).mean()
            plt.plot(np.array(dict[varname][prod_name][lead][area][prof]['time'])[ii],
                     rms_tmp, linestyle = '-',  linewidth = 1.6, color = list_color[ind_lead],
                     label = lead)
            #plt.plot(np.array(dict[varname][prod_name][area][prof]['time'])[ii],
            #         np.array(dict[varname][prod_name][area][prof]['rmsd'])[ii],
            #         linestyle = '-',  linewidth = 1.6, color = list_color[s],
            #         label = name_lab)
            ii = np.where(~np.isnan(np.array(dict[varname][prod_name][lead][area][prof]['bias'])))
            v_time = np.array(dict[varname][prod_name][lead][area][prof]['time'])[ii]
            #print(f'Echeance {lead}')
            #[print(dt.strftime('The date is %A %Y %b %d')) for dt in v_time]
            bias_tmp =  np.array(dict[varname][prod_name][lead][area][prof]['bias'])[ii]
            if  med_filtr:
                print(f'Data filtered {window}')
                if len(bias_tmp > 0):
                    var_filtre1 = medfilt(bias_tmp[:], window)
                    data = pd.Series(var_filtre1)
                    bias_tmp = data.rolling(window, center=True).mean()
            plt.plot(np.array(dict[varname][prod_name][lead][area][prof]['time'])[ii],
                     bias_tmp,
                     linestyle = '--', linewidth = 1.6, color = list_color[ind_lead])
            #plt.plot(np.array(dict[varname][prod_name][area][prof]['time'])[ii],
            #         np.array(dict[varname][prod_name][area][prof]['bias'])[ii],
            #         linestyle = '--', linewidth = 1.6, color = list_color[s])


    # ~~~~~~~~ Config plot, axes et sous-titres ~~~~~~~~~~~
    if varname in ['sla','sst']:
        plt.title(varname.upper(), fontsize=13, fontweight="bold")
    else:
        if isinstance(prof, (bytes, bytearray)):
            profval = str(prof.decode("utf-8"))
        else :
            profval = str(prof)
        plt.title(f'{varname.upper()} (depth: {profval})',
                  fontsize=13, fontweight="bold")
    ##if varname in ['sla']:
    ##    valmin = -0.05
    ##    valmax = 0.1
    ##if varname in ['sst']:
    ##    valmin = -0.5
    ##    valmax = 1.0

    plt.plot([datemin, datemax], [0,0], color = 'black', linestyle = '--', linewidth = 0.8)
    datemin = np.datetime64(datemin)
    datemax = np.datetime64(datemax)
    ax_fig.set_xlim(datemin, datemax)
    #if varname in ['sla','sst']:
    #    ax_fig.set_ylim(valmin, valmax)
    xax = ax_fig.get_xaxis()
    ax_fig.xaxis.set_major_locator(dates.YearLocator())
    ax_fig.set_xticklabels(ax_fig.get_xticks(), fontsize = 10)
    ax_fig.xaxis.set_major_formatter(dates.DateFormatter('%Y'))

    if leg and splot == 'single':
        plt.legend(loc=9, bbox_to_anchor=(0., -0.18, 1, 0.1), ncol=len(list_fcst),
                   fontsize = 9, edgecolor = 'black', facecolor = 'lavender')
    elif leg and splot == 'multi' and nb_var == 4:
        plt.legend(loc=9, bbox_to_anchor=(0., -0.29, 1, 0.1), ncol=len(list_fcst),
                   fontsize = 12, edgecolor = 'black', facecolor = 'lavender')
    elif leg and splot == 'multi' and nb_var == 2:
        plt.legend(loc=9, bbox_to_anchor=(0., -0.255, 1, 0.1), ncol=len(list_fcst),
                   fontsize = 10.5, edgecolor = 'black', facecolor = 'lavender')


    # ~~~~~~~~~~~~~~~ Ajout du nombre obs sur le plot ~~~~~~~~~~~~~~~~~~

    if skill == 0:
        ax1 = ax_fig.twinx()
        ax_fig.grid(axis='y', color='grey', linestyle='--', alpha=0.5, linewidth = 0.3)
        if system[0] in list_system:
            barlist=ax1.bar(np.array(dict[varname][system][lead][area][prof]['time']),
                            np.array(dict[varname][system][lead][area][prof]['nb_obs']),
                            alpha=0.14, width=1,linewidth=0,color="grey")
        else:
            barlist=ax1.bar(np.array(dict[varname][system][lead][area][prof]['time']),
                            np.array(dict[varname][system][lead][area][prof]['nb_obs']),
                            alpha=0.14, width=1,linewidth=0,color="grey")
        plt.ylabel("Number of observations", fontsize=12,color='darkgrey')
        ax1.tick_params(axis='y', colors='darkgrey',labelsize='small', length=6, pad = 1.5)

    plt.plot([0,0],[0,0.1], linewidth = 1.2, color = 'black',
             linestyle = '-', label = 'RMSD')
    plt.plot([0,0],[0,0.1], linewidth = 1.2, color = 'black',
             linestyle = '--', label = 'BIAS')

    plt.legend(loc=1, bbox_to_anchor=(0., 0.88, 0.08, 0.1), ncol=1,
               fontsize = 7, edgecolor = 'black', facecolor = 'white')

    return fig

