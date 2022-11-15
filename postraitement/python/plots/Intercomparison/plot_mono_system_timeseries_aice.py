# -*- coding: utf-8 -*-
"""
Created on Wed Nov 28 09:13:09 2017

@author: cszczypta
"""

#!/usr/bin/python
#========================================== 

import matplotlib
matplotlib.use('Agg')
import numpy as np
import numpy.ma as ma
from netCDF4 import Dataset
import datetime as d
import sys, os
from glob import glob
import matplotlib.pyplot as plt
#import param.Def_param_bulletin as params
import timeseries_plot as tsp
import scipy as sp
from scipy import signal


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


# ***************************************************************************
#
#    Ce programme permet de tracer les series temporelles sur une periode
#   donnee des differentes statistiques (RMSD et BIAIS) pour les differents 
#          jeux de donnees (HYCOM, PSY3, PSY4, GIOPS, BLK et FOAM)
#
# ***************************************************************************


# Configuration du plot
# ~~~~~~~~~~~~~~~~~~~~~~

SINGLE_PLOT = True
#False
MULTI_PLOT =False # True
GLO_AREA = False
CMEMS_AREA = True
dt_start_plot = '20170101'
dt_end_plot = '20211231'
list_color = ['y','deeppink','dodgerblue','mediumpurple','pink','turquoise','darkorange']
list_color = ['deeppink','y','mediumpurple','pink','turquoise']
list_color = ['red']
window = 30
window = 2
nf = 0 # Hincast: 0 ; Forecast: nbre heures echeance (12, 60, etc.)
metric_type = 'RMSD' # 'RMSD' or 'COR'
metric_type = 'PCT' # 'RMSD' or 'COR'
name_ech = 'best_estimate'

# Definition des chemins, des systemes, des variables et de la periode
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PATH_IN="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"
PATH_OUT = "./imgs/aice_out/"
SYSTEM = ['PSY4','GIOPS','FOAM','NERSC']
SYSTEM = ['GLO12V4']
VAR = ['seaice-concentration']
level_sla_stt = 0
level_t_s = 1
frame1="best"
frame2="forecast"
frame3="persistence"
tval=".20"
echeance="best estimate"
date1 = "2017-2021"
#date1 = "2016-2019"
#cla_areaini = params.liste_zone
#cla_depth = params.profondeur
#cla_areaini=['ARC','ANT']
ZONE="ARC"
#ZONE="ANT"
cla_areaini=[ZONE]
#SYSTEM = ['GIOPS','PSY4V3R1','FOAM','NERSC']
SYSTEM = ['GLO12V4']
#SYSTEM = ['GIOPS','PSY4V3R1','FOAM']
if ZONE == "ANT": SYSTEM = SYSTEM[:-1]
# ~~~~~~~~~~~ Definition des dates ~~~~~~~~~~~~~~~~~

dateCNESref   = d.datetime.strptime('19500101','%Y%m%d').toordinal()
dtst = d.datetime.strptime(dt_start_plot,'%Y%m%d')
dted = d.datetime.strptime(dt_end_plot,'%Y%m%d')

#frame1=frame2
# Lecture des stats pour les differents systemes 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dict={}
dict_tmp = {}

for v, varname in enumerate(VAR):

    dict_tmp[varname] = {} ; dict[varname] = {}

    if varname in ['sla','sst','seaice-concentration']: level = level_sla_stt
    elif varname in ['temperature','salinity']: level = level_t_s
    else: print('level not define')

    for s, prod in enumerate(SYSTEM):

        dict[varname][prod] = {} ; dict_tmp[varname][prod] = {}
        #print PATH_IN+ prod +"/timeseries/best/Stats_contable_timeseries_"+ZONE+"_"+prod+"_"+date1+"_seuil"+tval+"_"+frame1+".nc"
        print(PATH_IN+ prod +"/timeseries/best/Stats_contable_timeseries_"+ZONE+"_"+prod+"_"+date1+"_seuil"+tval+"_"+frame1+".nc")
        filename = glob(os.path.join(PATH_IN+ prod +"/timeseries/best/Stats_contable_timeseries_"+ZONE+"_"+prod+"_"+date1+"_seuil"+tval+"_"+frame1+".nc"))[0]
      #  filename = glob(os.path.join(PATH_IN+ prod+ '/product_quality_stats_GLOBAL_ANALYSIS_FORECAST_'+prod+'*nc'))[0]
        nc1_file = Dataset(filename, 'r')
        meandiff_oper_dt1 = nc1_file.variables['mean_diff_timeserie'][:]
        meandiff_oper_dt1=np.where(abs(meandiff_oper_dt1)>0.8,np.nan,meandiff_oper_dt1)
        rmsdiff_oper_dt1= nc1_file.variables['rms_diff_timeserie'][:]
        rmsdiff_oper_dt1=np.where(rmsdiff_oper_dt1>0.8,np.nan,rmsdiff_oper_dt1)
        nb_values_oper_dt1=nc1_file.variables['sum_values_timeserie'][:]
        PCT_dt1=nc1_file.variables['PCT_timeserie'][:]
        PCT_dt1 = np.where(PCT_dt1 <= 0.001 , np.nan, PCT_dt1)
        PCW_dt1=nc1_file.variables['PCW_timeserie'][:]
        PCW_dt1 = np.where(PCW_dt1 <= 0.001 , np.nan, PCW_dt1)
        PCI_dt1=nc1_file.variables['PCI_timeserie'][:]
        PCI_dt1 = np.where(PCI_dt1 <= 0.001 , np.nan, PCI_dt1)
        BIAS_dt1=nc1_file.variables['BIAS_timeserie'][:]
        BIAS_dt1 = np.where(BIAS_dt1 <= 0.01 , np.nan, BIAS_dt1)
        Hitice_dt1=nc1_file.variables['Hitice_timeserie'][:]
        Miss_dt1=nc1_file.variables['Miss_timeserie'][:]
        FalseAlarm_dt1=nc1_file.variables['FalseAlarm_timeserie'][:]
        HitWater_dt1=nc1_file.variables['Hitwater_timeserie'][:]
        timevalue = np.array((nc1_file.variables['time'][:]))
        vtime = timevalue[:]/86400 + dateCNESref
    ##    vtime = [ int(time)  for time in vtime ]
        #vtime = np.array((nc1_file.variables['time'][:])/86400 + dateCNESref)
        #print vtime[0:30]
       # vtime = (nc1_file.variables['time'][:])/86400 + dateCNESref
        area_name = cla_areaini
        #metric_name = ['PCT','BIAS','PCW']
        #fcst = f1.variables['forecasts'][:]
        #f1.close()
        #sys.exit(1)
        #num_ech, name_ech = echeance(fcst, nf)

        #rmsd = np.where(np.array(metric_name) == 'mean squared error')[0][0]
        #mean_obs = np.where(np.array(metric_name) == 'mean of reference')[0][0]     
        #mean_prod = np.where(np.array(metric_name) == 'mean of product')[0][0]     
        #nb_obs = np.where(np.array(metric_name) == 'number of data values')[0][0] 
        #cor = np.where(np.array(metric_name) == 'anomaly correlation')[0][0]   
        ini = False
        for a, area in enumerate(area_name):
            print(area_name) 
            dict[varname][prod][area] = {}
            dict_tmp[varname][prod][area] = {}
            dict_tmp[varname][prod][area]['PCT'] = PCT_dt1[:]
            dict_tmp[varname][prod][area]['PCW'] = PCW_dt1[:]
            dict_tmp[varname][prod][area]['PCI'] = PCI_dt1[:]
            dict_tmp[varname][prod][area]['BIAS'] = BIAS_dt1[:]
            dict_tmp[varname][prod][area]['RMSD'] = rmsdiff_oper_dt1[:]
            dict_tmp[varname][prod][area]['MD'] = meandiff_oper_dt1[:]
            dict_tmp[varname][prod][area]['nb_obs'] = nb_values_oper_dt1[:]

            TIME = []
            for t in range(len(vtime)):
                if SYSTEM  == "FOAM":
                    print(int(vtime[t]))
                    print(t)
                    print(d.date.fromordinal(int(vtime[t])))
                TIME.append(d.date.fromordinal(int(vtime[t])))
               # TIME.append(d.date.fromordinal(vtime[t]))

            dict[varname][prod][area]['time'] = TIME[int(window/2):-int(window/2)]
        print("OK")
    # ~~ On lisse la courbe en faisant une moyenne glissante des stats sur n jours ~~~

    for s, prod in enumerate(SYSTEM):
        if 'time' not in dict[varname][prod][area]: continue
        v_time = np.array(dict[varname][prod][area]['time'])
        for a, area in enumerate(area_name):
            MAT_TMP = np.zeros((len(v_time), 7))
            for t in range(len(v_time)):
                MAT_TMP[t,0] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['PCT'])[t:t+int(window)])
                MAT_TMP[t,1] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['nb_obs'])[t:t+int(window)])
                MAT_TMP[t,2] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['BIAS'])[t:t+int(window)])
                MAT_TMP[t,3] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['PCW'])[t:t+int(window)])
                MAT_TMP[t,4] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['PCI'])[t:t+int(window)])
                MAT_TMP[t,5] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['RMSD'])[t:t+int(window)])
                MAT_TMP[t,6] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['MD'])[t:t+int(window)])
            dict[varname][prod][area]['rmsd'] = MAT_TMP[:,5]
            dict[varname][prod][area]['bias'] = MAT_TMP[:,6]
            dict[varname][prod][area]['nb_obs'] = MAT_TMP[:,1]
            dict[varname][prod][area]['PCT'] = MAT_TMP[:,0]
            dict[varname][prod][area]['PCW'] = MAT_TMP[:,3]
            dict[varname][prod][area]['PCI'] = MAT_TMP[:,4]
            dict[varname][prod][area]['BIAS'] = MAT_TMP[:,2]



# ************************************************************************
#             Test pour tracer plusieurs plots simples
# ************************************************************************

list_to_plot=['PCT','PCI','BIAS','PCW','RMSD']
#list_to_plot=['RMSD']
if SINGLE_PLOT:
  for metric_type in list_to_plot:
    if GLO_AREA:
        area_ini = ['Full Domain']
    elif CMEMS_AREA:
        area_ini = area_name
    for area in area_ini:
        #a = np.where(np.array(area_name) == area)[0][0]
        for v, varname in enumerate(VAR):
        #for v, varname in enumerate(dict[varname]['PSY4V3R1'][area].keys()):
            if varname in ['sla','sst','seaice-concentration']: prof = ""
            prof = ""
            #elif varname in ['temperature','salinity']: prof = cla_depth[level_t_s]
            fig, splot, nb_var = tsp.fmtFig(area, name_ech)
            leg = True
            ax_fig = plt.subplot(1,1,1)
           # if cla_areaini[a] == 'ARC':
            f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof, dtst, dted, leg, list_color, splot,\
                    nb_var, echeance)
            #if area == 'ARC':
            #else:
            #f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM[:-1], prof, dtst, dted, leg, list_color, splot, nb_var, metric_type)

            if metric_type == 'RMSD':
                plt.savefig(PATH_OUT+cla_areaini[a]+'_rmsd_bias_'+varname+'_'+dt_start_plot+'-'+dt_end_plot+'.png',dpi=200)
            elif metric_type == 'COR':
                plt.savefig(PATH_OUT+cla_areaini[a]+'_correlation_'+varname+'_'+dt_start_plot+'-'+dt_end_plot+'.png',dpi=200)
            else:
                #ymin=0.4
                #ymax=1.0
                #plt.ylim(ymin,ymax)
                print((PATH_OUT+str(area)+'_'+str(metric_type)+'_'+dt_start_plot+'-'+dt_end_plot+'.png'))
                plt.savefig(PATH_OUT+str(area)+'_'+str(frame1)+'_'+str(metric_type)+'_'+dt_start_plot+'-'+dt_end_plot+'.png',dpi=200)
            plt.close()


# ************************************************************************
#                Test pour tracer des multiplots
# ************************************************************************

if MULTI_PLOT == True:
    if GLO_AREA:
        area_ini = ['Full Domain']
    elif CMEMS_AREA:
        area_ini = area_name
    for area in area_ini:
        print(area)
        #a = np.where(np.array(area_name) == area)[0][0]
        fig, splot, nb_var = tsp.fmtFig(area, name_ech, splot='multi', nb_var=len(VAR))
        leg = False
        print("OK1")
        for v, varname in enumerate(VAR):
            print(varname)
            if varname in ['sla','sst']: prof = cla_depth[level_sla_stt]
            elif varname in ['temperature','salinity']: prof = cla_depth[level_t_s]
            ax_fig = plt.subplot(len(VAR),1,v+1) 
            if (v+1) == len(VAR):
                leg = True
            print(area)
            f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof, dtst, dted, leg, list_color, splot, nb_var, metric_type)           
            #if area == 'ARC' or :
            #    print "CAS 1"
            #else:
            #    f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM[:-1], prof, dtst, dted, leg, list_color, splot, nb_var, metric_type)           
        if metric_type == 'RMSD':
            plt.savefig(PATH_OUT+cla_areaini[a]+'_rmsd_bias_'+dt_start_plot+'-'+dt_end_plot+'.png',dpi=200)
        elif metric_type == 'COR':
            plt.savefig(PATH_OUT+cla_areaini[a]+'_correlation_'+dt_start_plot+'-'+dt_end_plot+'.png',dpi=200)
        else:
            print((PATH_OUT+str(area)+'_'+str(metric_type)+'_'+dt_start_plot+'-'+dt_end_plot+'.png'))
            plt.savefig(PATH_OUT+str(area)+'_'+str(frame1)+'_'+str(metric_type)+'_'+dt_start_plot+'-'+dt_end_plot+'.png',dpi=200)
        plt.close()


