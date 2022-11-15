# -*- coding: utf-8 -*-
"""
Created on Wed Nov 28 09:13:09 2017

@author: cszczypta
"""

#!/usr/bin/python
#========================================== 

import sys
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.dates as dates
import matplotlib.pyplot as plt
import numpy as np


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
             ind_prof, prof, datemin, datemax, leg, list_color,
             splot, nb_var, skill):
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
        'BLK', 'GIOPS', 'NERSC', 'CGOFS', 'CMCC', 'PSY4V3R1', 'GLO12','FOAM_ORCA12']
    #list_system = ['PSY4','FOAM','HYCOM_RTOFS','BLK','GIOPS','NERSC','CMCC','PSY4V3R1']
    list_metric_aice = ['PCI','PCW','PCT','BIAS']
    for s, prod in enumerate(system):
        prod_name = prod
        if prod == "PSY4V3R1": prod_name = "PSY4"
        if prod_name in list_system:
            name_lab = prod
        elif prod == 0:
            name_lab = 'Hindcast'
            prod_name = f'{s}'
        else:
            name_lab = f'Fcst {prod} hours'
            prod_name = f'{s}'
        if 'time' not in dict[varname][prod_name][ind_prof][area]: continue
        if skill == 1:
            plt.plot(np.array(dict[varname][prod_name][ind_prof][area]['time']),
                     np.array(dict[varname][prod_name][ind_prof][area]['PSS']),
                     linewidth = 1.2, color = list_color[s], label = name_lab)
            plt.plot(np.array(dict[varname][prod_name][ind_prof][area]['time']),
                     np.array(dict[varname][prod_name][ind_prof][area]['CSS']),
                     linestyle = '--', linewidth = 1.2, color = list_color[s])
        else:
            plt.plot(np.array(dict[varname][prod_name][ind_prof][area]['time']),
                     np.array(dict[varname][prod_name][ind_prof][area]['rmsd']),
                     linewidth = 1.6, color = list_color[s], label = name_lab)
            plt.plot(np.array(dict[varname][prod_name][ind_prof][area]['time']),
                     np.array(dict[varname][prod_name][ind_prof][area]['bias']),
                     linestyle = '--', linewidth = 1.6, color = list_color[s])


    # ~~~~~~~~ Config plot, axes et sous-titres ~~~~~~~~~~~
    if varname in ['sla','sst']:
        plt.title(varname.upper(), fontsize=13, fontweight="bold")
    else:
        plt.title(varname.upper()+' (depth: '+str(prof.decode("utf-8"))+')',
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
        plt.legend(loc=9, bbox_to_anchor=(0., -0.18, 1, 0.1), ncol=len(system),
                   fontsize = 9, edgecolor = 'black', facecolor = 'lavender')
    elif leg and splot == 'multi' and nb_var == 4:
        if len(system) >  7:
            fontsize = 9
        else:
            fontsize = 12
        plt.legend(loc=9, bbox_to_anchor=(0., -0.29, 1, 0.1), ncol=len(system),
                   fontsize = fontsize, edgecolor = 'black', facecolor = 'lavender')
    elif leg and splot == 'multi' and nb_var == 2:
        plt.legend(loc=9, bbox_to_anchor=(0., -0.255, 1, 0.1), ncol=len(system),
                   fontsize = 10.5, edgecolor = 'black', facecolor = 'lavender')


    # ~~~~~~~~~~~~~~~ Ajout du nombre obs sur le plot ~~~~~~~~~~~~~~~~~~

    if skill == 0:
        ax1 = ax_fig.twinx()
        ax_fig.grid(axis='y', color='grey', linestyle='--', alpha=0.5, linewidth = 0.3)
        if system[0] in list_system:
            barlist=ax1.bar(np.array(dict[varname][system[0]][ind_prof][area]['time']),
                            np.array(dict[varname][system[0]][ind_prof][area]['nb_obs']),
                            alpha=0.14, width=1,linewidth=0,color="grey")
        else:
            barlist=ax1.bar(np.array(dict[varname][str(int(system[0]))][ind_prof][area]['time']),
                            np.array(dict[varname][str(int(system[0]))][ind_prof][area]['nb_obs']),
                            alpha=0.14, width=1,linewidth=0,color="grey")
        plt.ylabel("Number of observations", fontsize=12,color='darkgrey')
        ax1.tick_params(axis='y', colors='darkgrey',labelsize='small', length=6, pad = 1.5)

    plt.plot([0,0],[0,0.1], linewidth = 1.2, color = 'black',
             linestyle = '-', label = 'RMSD')
    plt.plot([0,0],[0,0.1], linewidth = 1.2, color = 'black',
             linestyle = '--', label = 'BIAS')
    #if splot == 'multi':
    #    print('------------')
    #    print('Plot multi')
    #    print('------------')
    #    plt.legend(loc=1, ncol=1, prop={'size': 5},
    #               edgecolor = 'black', facecolor = 'white')
    #else:
    plt.legend(loc=1, bbox_to_anchor=(0., 0.88, 0.08, 0.1), ncol=1,
               fontsize = 7, edgecolor = 'black', facecolor = 'white')

    return fig

