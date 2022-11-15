#coding: utf-8 -*-
"""
Created on Wed Apr 4 09:13:09 2017

@author: cszczypta
"""

#!/usr/bin/python
#========================================== 

import matplotlib
#matplotlib.use('TkAgg')
import os, sys
import numpy as np
import netCDF4
import matplotlib.pyplot as plt
from os.path import dirname
#sys.path.append(dirname(__file__)+'/../../../../modules/')
from matplotlib.ticker import FixedLocator


# Functions
# ~~~~~~~~~~~~~

def graphics_design(ax_plot, mat_plot, AR):

    ax_plot.plot(mat_plot[:,0],
                 depth,
                 color = 'darkturquoise',
                 linewidth = 2.3,
                 label = 'Mean diff')
    ax_plot.plot(mat_plot[:,2],
                 depth,
                 color = 'y',
                 linewidth = 1.4,
                 label = '99% percentile')
    ax_plot.plot(mat_plot[:,1],
                 depth,
                 color = 'y',
                 linewidth = 1.4)
    ax_plot.fill_betweenx(depth,
                          mat_plot[:,4],
                          mat_plot[:,3],
                          facecolor='blue',
                          alpha=0.26,
                          label = '95% percentile')
    ax_plot.fill_betweenx(depth,
                          mat_plot[:,6],
                          mat_plot[:,5],
                          facecolor='blue',
                          alpha=0.46,
                          label = '75% percentile')
    ax_plot.set_ylim(0,2000)
    ax_plot.set_xlim(-xl[v][AR],xl[v][AR])
    for tick in ax_plot.get_xaxis().get_major_ticks():
        tick.set_pad(6)
    formatter = matplotlib.ticker.StrMethodFormatter("{x:0.2f}")
    ax_plot.xaxis.set_major_formatter(formatter)
    plt.title(name_area[AR], fontsize = 11, y=1.02)
    ax_plot.invert_yaxis()
    plt.ylabel('Depth (m)',
               color='black',
               fontsize = 10.8,
               fontweight = 'bold')
    plt.xlabel(unit[v],
               color='grey',
               fontsize = 9,
               fontweight = 'bold')
    ax_plot.grid(color='black',
                 linestyle='--',
                 alpha=0.5,
                 linewidth = 0.3)


# Config and path
# ~~~~~~~~~~~~~~~~~~
SYSTEM = 'GLO12V4'
#SYSTEM = 'PSY4V3R1'
YEAR = '2019'
PATH_IN = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+ \
          'Comparaison_systemes/Error_profiles/'+SYSTEM+'/'
PATH_OUT = './imgs/'
if not os.path.exists(PATH_OUT):
    os.makedirs(PATH_OUT)

var = ['temperature','salinity']
unit = {'temperature': 'Celsius', 'salinity': 'PSU'}
dict_AREA = {'AREA1': ['GLO','MED'], 'AREA2': ['SAT', 'SPA'], 'AREA3': ['ACC','ARC'], \
             'AREA4': ['TPA','TAT', 'IND'], 'AREA5': ['NPA','NAT']}
xl = {'temperature': {'GLO': 0.4, 'MED': 1, 'TPA': 0.5, 'TAT': 1.4, 'IND': 1.4, \
                      'NPA': 0.65, 'NAT': 1.2, 'ACC': 0.7, 'ARC': 2.6, 'SAT': 1.2, 'SPA': 0.4}, \
      'salinity': {'GLO': 0.1, 'MED': 0.4, 'TPA': 0.1, 'TAT': 0.3, 'IND': 0.3, \
                   'NPA': 0.1, 'NAT': 0.3, 'ACC': 0.15, 'ARC': 1.5, 'SAT': 0.2, 'SPA': 0.08}}
name_area = {'ACC': 'Antarctic Circumpolar', 'ARC': 'Arctic Ocean', 'IND': 'Indian Ocean', \
             'GLO': 'Global Ocean', 'MED': 'Mediterranean Sea', \
             'NAT': 'North Atlantic Ocean', 'NPA': 'North Pacific Ocean', \
             'SAT': 'South Atlantic Ocean', 'SPA': 'South Pacific Ocean', \
             'TAT': 'Tropical Atlantic Ocean', 'TPA': 'Tropical Pacific Ocean'}
filename = f'product_quality_stats_GLOBAL_ANALYSIS_FORECAST_{SYSTEM}_'\
           f'{YEAR}0101_{YEAR}1231_profile_percentile_'

# Read stats and plot graphics
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

for A in dict_AREA:
    AREA = dict_AREA[A]
    print(f'{AREA=}')
    double_area = False ; triple_area = False
    filename1 = filename+AREA[0]+'.nc'
    if len(AREA) > 1:
        filename2 = filename+AREA[1]+'.nc'
        double_area = True
        if len(AREA) == 3:
            filename3 = filename+AREA[2]+'.nc'
            triple_area = True

    for v in var:
        print(f'{v=}')
        # Read data
        nc = netCDF4.Dataset(PATH_IN+filename1,'r')
        var_mat = nc.variables['stats_'+v][0,:,:] * -1
        depth = nc.variables['depths'][:]
        nc.close()
        if double_area:
            nc = netCDF4.Dataset(PATH_IN+filename2,'r')
            var_mat2 = nc.variables['stats_'+v][0,:,:] * -1
            nc.close()
        if triple_area:
            nc = netCDF4.Dataset(PATH_IN+filename3,'r')
            var_mat3 = nc.variables['stats_'+v][0,:,:] * -1
            nc.close()

        # Dray figure
        if not double_area:
            fig = plt.figure(figsize = (6,8))
            fig.subplots_adjust(left = 0.15, bottom = 0.14,
                                right = 0.92, top = 0.89, wspace = 0.5, hspace = 0.28)
            ax = plt.subplot(1,1,1)
        else:
            if not triple_area:
                fig = plt.figure(figsize = (10,8))
                fig.subplots_adjust(left = 0.08, bottom = 0.09,
                                    right = 0.96, top = 0.89, wspace = 0.2, hspace = 0.28)
                ax2 = plt.subplot(1,2,2)
            if triple_area:
                fig = plt.figure(figsize = (15,8))
                fig.subplots_adjust(left = 0.06, bottom = 0.09,
                                    right = 0.977, top = 0.89, wspace = 0.25, hspace = 0.28)
                ax3 = plt.subplot(1,3,3)
                graphics_design(ax3, var_mat3, AREA[2])
                ax2 = plt.subplot(1,3,2)

            graphics_design(ax2, var_mat2, AREA[1])
            if triple_area: ax = plt.subplot(1,3,1)
            else: ax = plt.subplot(1,2,1)

        print(f'Plot figure {PATH_OUT}')
        fig.suptitle(SYSTEM+': '+v+' vertical profiles - '+YEAR, fontsize = 12.8, \
                     fontweight='bold', color='black', y=0.97)
        graphics_design(ax, var_mat, AREA[0])
        plt.legend(loc=9, bbox_to_anchor=(0.27, 0.07, 1, 0.1), ncol=1, fontsize = 9, \
                   edgecolor = 'black', facecolor = 'white', shadow=True)
        plt.savefig(PATH_OUT+SYSTEM+'_'+A+'_profil_'+v+'_'+YEAR+'_obs-mod.png',dpi=200)
        plt.close()
