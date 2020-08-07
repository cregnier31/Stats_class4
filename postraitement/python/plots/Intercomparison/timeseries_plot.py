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
        print '************ config not found ************'
        sys.exit()
    
    plt.suptitle(area+' - '+name_ech,fontsize=15.5+nb_var,color='red')   
    
    return fig, splot, nb_var


def plotStat(fig, ax_fig, dict, varname, area, system, prof, datemin, datemax, leg, list_color, splot, nb_var, skill):
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

    list_metric_aice = ['PCI','PCW','PCT','BIAS']
    for s, prod in enumerate(system):
        if prod in ['PSY4','ENSMEAN','PSY3','FOAM','HYCOM_RTOFS','BLK','GIOPS','NERSC']: 
            name_lab = prod
            prod_name = prod
        elif prod == 0:
            name_lab = 'Hindcast'
            prod_name = str(int(prod))
        else:
            name_lab = 'Fcst '+str(int(prod))+' hours'
            prod_name = str(int(prod))
        if 'time' not in dict[varname][prod_name][area]: continue
        if skill == 1:
            plt.plot(np.array(dict[varname][prod_name][area]['time']), np.array(dict[varname][prod_name][area]['PSS']), linewidth = 1.2, color = list_color[s], label = name_lab)
            plt.plot(np.array(dict[varname][prod_name][area]['time']), np.array(dict[varname][prod_name][area]['CSS']), linestyle = '--', linewidth = 1.2, color = list_color[s])
        else:
            plt.plot(np.array(dict[varname][prod_name][area]['time']), np.array(dict[varname][prod_name][area]['rmsd']), linewidth = 1.6, color = list_color[s], label = name_lab)
            plt.plot(np.array(dict[varname][prod_name][area]['time']), np.array(dict[varname][prod_name][area]['bias']), linestyle = '--', linewidth = 1.6, color = list_color[s])


    # ~~~~~~~~ Config plot, axes et sous-titres ~~~~~~~~~~~
    if varname in ['sla','sst']:
        plt.title(varname.upper(), fontsize=13, fontweight="bold")
    else:
        plt.title(varname.upper()+' (depth: '+prof+')', fontsize=13, fontweight="bold")
    plt.plot([datemin, datemax], [0,0], color = 'black', linestyle = '--', linewidth = 0.8)
    datemin = np.datetime64(datemin)
    datemax = np.datetime64(datemax)
    ax_fig.set_xlim(datemin, datemax)
    xax = ax_fig.get_xaxis()
    ax_fig.xaxis.set_major_locator(dates.YearLocator())
    ax_fig.set_xticklabels(ax_fig.get_xticks(), fontsize = 10)
    ax_fig.xaxis.set_major_formatter(dates.DateFormatter('%Y'))
    
    if leg and splot == 'single':
        plt.legend(loc=9, bbox_to_anchor=(0., -0.18, 1, 0.1), ncol=len(system), fontsize = 9, edgecolor = 'black', facecolor = 'lavender')
    elif leg and splot == 'multi' and nb_var == 4:
        plt.legend(loc=9, bbox_to_anchor=(0., -0.29, 1, 0.1), ncol=len(system), fontsize = 12, edgecolor = 'black', facecolor = 'lavender')
    elif leg and splot == 'multi' and nb_var == 2:
        plt.legend(loc=9, bbox_to_anchor=(0., -0.255, 1, 0.1), ncol=len(system), fontsize = 10.5, edgecolor = 'black', facecolor = 'lavender')


    # ~~~~~~~~~~~~~~~ Ajout du nombre obs sur le plot ~~~~~~~~~~~~~~~~~~

    if skill == 0:
        ax1 = ax_fig.twinx()
        ax_fig.grid(axis='y', color='grey', linestyle='--', alpha=0.5, linewidth = 0.3)
        if system[0] in ['PSY4','PSY3','FOAM','HYCOM_RTOFS','BLK','GIOPS','NERSC']:
            barlist=ax1.bar(np.array(dict[varname][system[0]][area]['time']), np.array(dict[varname][system[0]][area]['nb_obs']),alpha=0.14, width=1,linewidth=0,color="grey")   
        else:
            barlist=ax1.bar(np.array(dict[varname][str(int(system[0]))][area]['time']), np.array(dict[varname][str(int(system[0]))][area]['nb_obs']),alpha=0.14, width=1,linewidth=0,color="grey")   
        plt.ylabel("Number of observations", fontsize=12,color='darkgrey')  
        ax1.tick_params(axis='y', colors='darkgrey',labelsize='small', length=6, pad = 1.5)

    plt.plot([0,0],[0,0.1], linewidth = 1.2, color = 'black', linestyle = '-', label = 'RMSD')
    plt.plot([0,0],[0,0.1], linewidth = 1.2, color = 'black', linestyle = '--', label = 'BIAS')

    plt.legend(loc=1, bbox_to_anchor=(0., 0.88, 0.08, 0.1), ncol=1, fontsize = 7, edgecolor = 'black', facecolor = 'white')

    return fig

