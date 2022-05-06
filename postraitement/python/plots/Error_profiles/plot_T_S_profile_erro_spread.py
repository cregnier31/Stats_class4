# -*- coding: utf-8 -*-
"""
Created on Wed Apr 4 09:13:09 2017

@author: cszczypta
"""

#!/usr/bin/python
#========================================== 

import matplotlib
matplotlib.use('TkAgg')
import os, sys
import numpy as np
import netCDF4
import matplotlib.pyplot as plt
from os.path import dirname
sys.path.append(dirname(__file__)+'/../../../../modules/')
import param.Def_param_bulletin as params

# ************************************************************************
#                           FONCTIONS
# ************************************************************************


# ~~~~~~~~~~~~~~~~~~~~~~ Format nom  ~~~~~~~~~~~~~~~

def pull_names(name_data):
    names = []
    if isinstance(name_data, np.ma.masked_array):
        for letters in name_data:
            names.append((''.join(letters.data)).strip())
    else:
        for letters in name_data:
            names.append((''.join(letters)).strip())
    return names

# ~~~~~~~~~~~~~~~~~~~~~~ Determiner l'echeance consideree ~~~~~~~~~~~~~~~

def echeance(fcst, nf):
    num_ech = np.where(fcst == nf)[0][0]
    if nf == 0:
        name_ech = 'Hindcast'
    else:
        name_ech = 'Forecast '+str(nf)+' hours'

    return num_ech, name_ech


PATH_IN = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/Error_profiles/'
PATH_OUT = './imgs/'
SYSTEM = ['FOAM','PSY4V3R1','HYCOM_RTOFS','BLK','GIOPS', 'ENSMEAN']
SYSTEM = ['FOAM','PSY4V3R1','HYCOM_RTOFS','BLK','GIOPS', 'CGOFS']
xl_temp = [0.6, 2, 3, 0.5, 0.8, 1.3, 1, 1, 0.8, 0.8, 0.5, 1.2, 0.6, 3]
xl_sal = [0.15, 0.8, 0.8, 0.6, 0.2, 0.4, 0.4, 1, 0.2, 0.3, 0.1, 0.3, 0.15, 3]
xl_sal = [0.15, 0.8, 0.8, 0.25, 0.2, 0.4, 0.4, 1, 0.2, 0.3, 0.1, 0.3, 0.15, 3]
var = ['temperature','salinity']
unit = ['Celsius','PSU']
AREA = [AREA.decode('utf8') for AREA in params.liste_zone]
YEAR = 2018
nf = 156 # Hincast: 0 ; Forecast: nbre heures echeance (12, 60, etc.)


# ~~~~~~~~~~~~~~~~~~~~~~~ Determiner les zones CMEMS ~~~~~~~~~~~~~~~~~~

filename = 'product_quality_stats_GLOBAL_ANALYSIS_FORECAST_PSY4V3R1_20180101_20181231_profile_percentile_GLO.nc'
nc = netCDF4.Dataset(PATH_IN+filename,'r')
fcst = nc.variables['forecast'][:]
num_ech, name_ech = echeance(fcst, nf)
nc.close()
print('OK1')
for ar, area in enumerate(AREA):
        print (area)
#    if area == "GLO":
        #    if area != 'GLO': continue
        for num_v,v in enumerate(var):
            fig = plt.figure(figsize = (8,8))
            fig.subplots_adjust(left = 0.1, bottom = 0.12,
                                right = 0.97, top = 0.905, wspace = 0.5, hspace = 0.28)
            fig.suptitle(v.upper()+': '+area+' - '+name_ech, fontsize = 14, fontweight='bold', color='r')
            for s, syst in enumerate(SYSTEM):
    #            filename = 'product_quality_stats_GLOBAL_ANALYSIS_FORECAST_'+syst+'_'+str(YEAR)+'0101_'+str(YEAR)+'1231_profile_percentile_'+area+'.nc'
                filename = 'product_quality_stats_GLOBAL_ANALYSIS_FORECAST_'+syst+'_20180101_20181231_profile_percentile_'+area+'.nc'
                nc = netCDF4.Dataset(PATH_IN+filename,'r')
                var_mat = nc.variables['stats_'+v][num_ech,:,:]
                depth = nc.variables['depths'][:]
                nc.close()
                ax = plt.subplot(2,3,s+1)
                print(("System %s " %(syst)))
                print(("Variable %s " %(v)))
                print(np.nanmax(var_mat[:,0]))
                print((var_mat[:,0]))
                print (depth)
                ax.plot(var_mat[:,0], depth, color = 'darkturquoise', linewidth = 2.3, label = 'Mean error (model-obs)')
                ax.plot(var_mat[:,2], depth, color = 'y', linewidth = 1.4, label = '99 %')
                ax.plot(var_mat[:,1], depth, color = 'y', linewidth = 1.4)
                ax.fill_betweenx(depth, var_mat[:,4], var_mat[:,3], facecolor='blue', alpha=0.26, label = '95 %')
                ax.fill_betweenx(depth, var_mat[:,6], var_mat[:,5], facecolor='blue', alpha=0.46, label = '75 %')
    #            ax.fill_between(var_mat[:,5], var_mat[:,0]+var_mat[:,5], depth, facecolor='darkgrey', alpha=1)
                plt.ylim([0,2000])
                if v == 'temperature':
                    plt.xlim([-xl_temp[ar],xl_temp[ar]])
                elif v == 'salinity':
                    plt.xlim([-xl_sal[ar],xl_sal[ar]])
                plt.title(syst, fontsize = 11, fontweight='bold')
                plt.gca().invert_yaxis()
                plt.ylabel('depth (m)', color='grey',fontsize = 9, fontweight = 'bold')
                plt.xlabel(unit[num_v], color='grey',fontsize = 9, fontweight = 'bold')
            plt.legend(loc=9, bbox_to_anchor=(-1.5, -0.28, 1, 0.1), ncol=4, fontsize = 10, edgecolor = 'black', facecolor = 'white')
            
    #        plt.savefig(PATH_OUT+area+'_profile_percentile_'+v+'_'+str(YEAR)+'.png',dpi=200)
            plt.savefig(PATH_OUT+area+'_profile_percentile_'+str(nf)+'H'+v+'_2017-2018.png',dpi=200)
            plt.close()

