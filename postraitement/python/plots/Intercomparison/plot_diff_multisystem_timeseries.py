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
sys.path.append("../../../../modules/")

import matplotlib.pyplot as plt
import param.Def_param_bulletin as params
import timeseries_plot as tsp
import scipy as sp
from scipy import signal
from utils import pull_names, echeance

# ************************************************************************
#                           FONCTIONS
# ************************************************************************



# ***************************************************************************
#
#    Ce programme permet de tracer les series temporelles sur une periode
#   donnee des differentes statistiques (RMSD et BIAIS) pour les differents 
#          jeux de donnees (HYCOM, PSY3, PSY4, GIOPS, BLK et FOAM)
#
# ***************************************************************************

def read_stats(filename, prod, varname, level, dict_tmp, dict):
    try:
        f1 = Dataset(filename, 'r', format='NETCDF4')
    except Exception as e:
        raise RuntimeError(f'Failed to open file {filename}') from e

    if 'stats_'+varname in f1.variables:
        stat_var = f1.variables['stats_'+varname][:]
        stat_var = np.where(stat_var.mask, np.nan, stat_var)
        ll_stat = True
    else:
        ll_stat = False

    rla_name = f1.variables['area_names'][:]
    area_name = pull_names(rla_name)
    #if GLO_AREA:
    #    area_name = ['Full Domain']
    rla_metric = f1.variables['metric_names'][:]
    metric_name = pull_names(rla_metric)
    vtime = (f1.variables['time'][:])/24 + dateCNESref
    fcst = f1.variables['forecasts'][:]
    f1.close()
    num_ech, name_ech = echeance(fcst, nf)
    rmsd = np.where(np.array(metric_name) == 'mean squared error')[0][0]
    mean_obs = np.where(np.array(metric_name) == 'mean of reference')[0][0]
    mean_prod = np.where(np.array(metric_name) == 'mean of product')[0][0]
    nb_obs = np.where(np.array(metric_name) == 'number of data values')[0][0]
    cor = np.where(np.array(metric_name) == 'anomaly correlation')[0][0]
    ini = False
    if prod == "PSY4V3R1": prod = "PSY4"
    if prod == "GLO12V4": prod = "GLO12"
    if prod == "PSY3V3R3": prod = "PSY3"
    dict[varname][prod] = {}
    dict_tmp[varname][prod] = {}
    dict[varname][prod][level] = {}
    dict_tmp[varname][prod][level] = {}

    for a, area in enumerate(area_name):
        dict[varname][prod][level][area] = {}
        dict_tmp[varname][prod][level][area] = {}
        if ll_stat:
            dict_tmp[varname][prod][level][area]['rmsd'] = \
                stat_var[:, num_ech, level, rmsd, a]
            dict_tmp[varname][prod][level][area]['bias'] = \
                stat_var[:, num_ech, level, mean_prod, a] - \
                        stat_var[:,0, level, mean_obs, a]
            dict_tmp[varname][prod][level][area]['nb_obs'] = \
                stat_var[:, num_ech, level, nb_obs, a]
            dict_tmp[varname][prod][level][area]['cor_ano'] = \
                stat_var[:, num_ech, level, cor, a]
        TIME = []
        for t in range(len(vtime)):
            TIME.append(d.date.fromordinal(int(vtime[t])))
        if ll_stat:
            dict[varname][prod][level][area]['time'] = \
                TIME[int(window/2):-int(window/2)]
    return dict_tmp, dict, area_name, name_ech


# Configuration du plot
# ~~~~~~~~~~~~~~~~~~~~~~

SINGLE_PLOT = True
MULTI_PLOT = False
GLO_AREA = False
CMEMS_AREA = True
skill = 0
#dt_start_plot_ini = ['20140101','20161101']
#dt_end_plot_ini = ['20181231', '20210531']
#list_color = ['red', 'black']
dt_start_plot_ini = ['20150101','20161101','20150101','20150101','20150101','20160901','20150101','20210110','20210101']
dt_end_plot_ini = ['20220430', '20220430','20220430','20220430','20220430','20200830','20220430','20220430','20220326']
#dt_start_plot_ini = ['20150101', '20161101', '20150101', '20150101', '20160901', '20150101', '20210110', '20210101']
#dt_end_plot_ini = ['20220430', '20220430', '20220430', '20220430', '20200830', '20220430', '20220430', '20220326']
#dt_start_plot_ini = ['20150101','20161101']
#dt_end_plot_ini = ['20220430', '20220430']
list_color = ['y','deeppink','dodgerblue','mediumpurple','pink','turquoise','darkorange','green','gold']
#list_color = ['y','deeppink','mediumpurple','pink','turquoise','darkorange','green','gold']
#list_color = ['y','deeppink']
window = 30
nf = 0 # Hincast: 0 ; Forecast: nbre heures echeance (12, 60, etc.)

if nf == 0 :
    type_ech = "HINDCAST"
elif nf == 12 :
    type_ech = "FCST1D"
elif nf == 60 :
    type_ech = "FCST3D"
elif nf == 108 :
    type_ech = "FCST5D"
else :
    print ("Type not defined")
    sys.exit(1)


# Definition des chemins, des systemes, des variables et de la periode
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PATH_IN = '/home/cregnier/Gitlab/TEP_CLASS4/postraitement/python/plots/Intercomparison/'
depth_comp="0-5000m"
PATH_OUT = f'{PATH_IN}img_GODAE/{depth_comp}/'
if not os.path.isdir(PATH_OUT):
    os.makedirs(PATH_OUT)
DATA_IN = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'
SYSTEM = ['FOAM','PSY4V3R1','ENSMEAN','HYCOM_RTOFS','BLK','CGOFS','GIOPS','CMCC', 'FOAM_ORCA12']
#SYSTEM = ['FOAM', 'PSY4V3R1', 'HYCOM_RTOFS','BLK','CGOFS','GIOPS','CMCC', 'FOAM_ORCA12']
#SYSTEM = ['FOAM', 'PSY4V3R1']
VAR = ['salinity', 'temperature', 'sla', 'sst']
#VAR = ['sst']
level_sla_stt = [0]
level_t_s = [0, 1, 2, 3, 4, 5]
cla_areaini = params.liste_zone
cla_depth = params.profondeur6
print (cla_depth)
# ~~~~~~~~~~~ Definition des dates ~~~~~~~~~~~~~~~~~

dt_start_plot = "20150101"
dt_end_plot = "20220430"
dateCNESref = d.datetime.strptime('19500101','%Y%m%d').toordinal()
dtst = d.datetime.strptime(dt_start_plot,'%Y%m%d')
dted = d.datetime.strptime(dt_end_plot,'%Y%m%d')


# Lecture des stats pour les differents systemes 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dict={}
dict_tmp = {}

for v, varname in enumerate(VAR):
    dict_tmp[varname] = {} ; dict[varname] = {}

    if varname in ['sla','sst']: list_level = level_sla_stt
    elif varname in ['temperature','salinity']: list_level = level_t_s
    else: print ('level not define')
    for level in list_level:
        for s, prod in enumerate(SYSTEM):
            dt_start_plot = dt_start_plot_ini[s]
            dt_end_plot = dt_end_plot_ini[s]
            try:
                file = f'{DATA_IN}{prod}/Stats_GODAE/NETCDF/{depth_comp}'\
                       f'/product_quality_stats_GLOBAL_ANALYSIS_FORECAST_'\
                       f'{prod}_{dt_start_plot}_{dt_end_plot}.nc'
                filename = glob(file)[0]
            except Exception as e:
                raise RuntimeError(file) from e
            dict_tmp, dict, area_name, name_ech = \
                read_stats(filename, prod, varname, level, dict_tmp, dict)
            print (f'READ stats system {varname=} {prod=} {level=} {area_name=}')
    # ~~ On lisse la courbe en faisant une moyenne glissante des stats sur n jours ~~~
    print (f'Read and Filter out the timeserie {varname}')
    for level in list_level:
        for s, prod in enumerate(SYSTEM):
            if prod == "PSY4V3R1": prod = "PSY4"
            if prod == "GLO12V4": prod = "GLO12"
            if prod == "PSY3V3R3": prod = "PSY3"
            for a, area in enumerate(area_name):
              #if area == "Full Domain":
                #if area == "Indian Ocean":
                print('_______________')
                print(f'{dict[varname][prod]}')
                if 'time' not in dict[varname][prod][level][area]: continue
                v_time = np.array(dict[varname][prod][level][area]['time'])
                MAT_TMP = np.zeros((len(v_time), 4))
                for t in range(len(v_time)):
                    MAT_TMP[t,0] = np.nanmedian(np.array(dict_tmp[varname][prod][level][area]['rmsd'])[t:t+int(window)])
                    MAT_TMP[t,1] = np.nanmedian(np.array(dict_tmp[varname][prod][level][area]['bias'])[t:t+int(window)])
                    MAT_TMP[t,2] = np.nanmedian(np.array(dict_tmp[varname][prod][level][area]['nb_obs'])[t:t+int(window)])
                    MAT_TMP[t,3] = np.nanmedian(np.array(dict_tmp[varname][prod][level][area]['cor_ano'])[t:t+int(window)])
                dict[varname][prod][level][area]['rmsd'] = np.sqrt(MAT_TMP[:,0])
                dict[varname][prod][level][area]['bias'] = MAT_TMP[:,1]
                dict[varname][prod][level][area]['nb_obs'] = MAT_TMP[:,2]
                dict[varname][prod][level][area]['cor_ano'] = MAT_TMP[:,3]
        print(f'{prod} ok')


# ************************************************************************
#             Test pour tracer plusieurs plots simples
# ************************************************************************

#SYSTEM = ['GLO12','PSY4']
comp_name = 'vs'.join(SYSTEM)
comp_name = 'multisysGODAE'
if SINGLE_PLOT:
    print ("Single_plot")
    if GLO_AREA:
        area_ini = ['Full Domain']
    elif CMEMS_AREA:
        area_ini = area_name
    for level in list_level:
        for area in area_ini:
          if area == "Full Domain":
            a = np.where(np.array(area_name) == area)[0][0]
            for v, varname in enumerate(VAR):
                prof = cla_depth[level]
                #if varname in ['sla','sst']: prof = cla_depth[level_sla_stt]
                #elif varname in ['temperature','salinity']: prof = cla_depth[level_t_s]
                for s, prod in enumerate(SYSTEM):
                    if prod == "PSY4V3R1": prod = "PSY4"
                    fig, splot, nb_var = tsp.fmtFig(area, name_ech)
                    leg = True
                    ax_fig = plt.subplot(1,1,1)
                    if cla_areaini[a] == 'ARC':
                        f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
                                         dtst, dted, leg, list_color, splot, nb_var, skill)
                    else:
                        f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
                                         dtst, dted, leg, list_color, splot, nb_var, skill)
                        #f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
                        #                 dtst, dted, leg, list_color, splot, nb_var, skill)
                        #plt.plot(np.array(dict[varname][prod][area]['time']),
                        #         np.array(dict[varname][prod][area]['rmsd']),
                        #         linewidth = 1.6, color = list_color[s], label = prod)
                        #plt.plot(np.array(dict[varname][prod][area]['time']),
                        #         np.array(dict[varname][prod][area]['bias']),
                        #         linestyle = '--', linewidth = 1.6, color = list_color[s])
                        #nb_obs = np.array(dict[varname][str(int(system[0]))][area]['nb_obs'])
                areavalue = cla_areaini[a].decode("utf-8")
                profvalue = prof.decode("utf-8")
                filename_out = f"{PATH_OUT}{areavalue}_rmsd_bias_"\
                               f"{varname}_{comp_name}_{dt_start_plot}-{dt_end_plot}-{profvalue}.png"
                plt.savefig(filename_out, dpi=200)


## ************************************************************************
##                Test pour tracer des multiplots
## ************************************************************************
##SYSTEM = ['FOAM','PSY4','ENSMEAN','HYCOM_RTOFS','BLK','CGOFS','GIOPS','CMCC']
##SYSTEM = ['FOAM','PSY4','HYCOM_RTOFS','BLK','GIOPS','CMCC']
#
#if MULTI_PLOT == True:
#    print ("Multiplot")
#    if GLO_AREA:
#        area_ini = ['Full Domain']
#    elif CMEMS_AREA:
#        area_ini = area_name
#    for area in area_ini:
#        a = np.where(np.array(area_name) == area)[0][0]
#        fig, splot, nb_var = tsp.fmtFig(area, name_ech, splot='multi', nb_var=len(VAR))
#        leg = False
#        for v, varname in enumerate(VAR):
#            #if varname in ['sla','sst']: prof = cla_depth[level_sla_stt]
#            if varname in ['sla','sst']: prof = "" # cla_depth[level_sla_stt]
#            elif varname in ['temperature','salinity']: prof = cla_depth[level_t_s]
###
#            title = f'{region} {prof}'
#            title_img = dir_plot+'Serie_temp_meanrms_'+var+'_'+region+'_'+modele1+'_'+prof+"_filtr.png"
#            timeserie = Plot_TS(datefmt='%Y').plot_timeserie(title, time_ref_1, HDCT1_rmsdiff,
#                                                             title_img, label=modele1, nb_obs=nb_cumul[:],
#            timeserie =  timeserie.overplot(time_ref_1, HDCT1_meandiff[:], color1='red', linestyle='--')
#                                            timeserie =  timeserie.overplot(time_ref_2, HDCT2_rmsdiff[:],
#                                            color1='black', label=modele2, linestyle='-')
#            timeserie.savefig(title_img)
###
#            ax_fig = plt.subplot(len(VAR),1,v+1) 
#            if (v+1) == len(VAR):
#                leg = True
#            if cla_areaini[a] == 'ARC':
#                f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
#                                 dtst, dted, leg, list_color, splot, nb_var, skill)
#            else:
#                f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
#                                 dtst, dted, leg, list_color, splot, nb_var, skill)
#        print (str(dt_start_plot),str(type_ech),str(dt_end_plot),str(type_ech))
#        if not os.path.exists(PATH_OUT+str(type_ech)+'/'):
#            os.makedirs(PATH_OUT+str(type_ech)+'/')
#        areavalue = cla_areaini[a].decode("utf-8")
#        filename_out = f"{PATH_OUT}{type_ech}/{areavalue}_rmsd_bias_"\
#                        f"{comp_name}_{dt_start_plot}-{dt_end_plot}_{type_ech}.png"
#        plt.savefig(filename_out, dpi=200)
#        plt.close()


