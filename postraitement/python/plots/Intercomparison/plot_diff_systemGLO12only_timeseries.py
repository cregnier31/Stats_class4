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

def read_stats(filename,prod, varname, dict_tmp, dict):
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
    #if prod == "GLO12V4": prod = "GLO12"
    if prod == "PSY3V3R3": prod = "PSY3"
    dict[varname][prod] = {} ; dict_tmp[varname][prod] = {}
    for a, area in enumerate(area_name):
      #if area == "Full Domain":
        dict[varname][prod][area] = {}
        dict_tmp[varname][prod][area] = {}
        if ll_stat:
            dict_tmp[varname][prod][area]['rmsd'] = \
                stat_var[:, num_ech, level,rmsd, a]
            dict_tmp[varname][prod][area]['bias'] = \
                stat_var[:, num_ech, level,mean_prod, a] - \
                        stat_var[:,0, level,mean_obs, a]
            dict_tmp[varname][prod][area]['nb_obs'] = \
                stat_var[:, num_ech, level, nb_obs, a]
            dict_tmp[varname][prod][area]['cor_ano'] = \
                stat_var[:, num_ech, level, cor, a]
        TIME = []
        for t in range(len(vtime)):
            TIME.append(d.date.fromordinal(int(vtime[t])))
        if ll_stat:
            dict[varname][prod][area]['time'] = \
                TIME[int(window/2):-int(window/2)]
    return dict_tmp, dict, area_name, name_ech


# Configuration du plot
# ~~~~~~~~~~~~~~~~~~~~~~

SINGLE_PLOT = True
MULTI_PLOT = False
GLO_AREA = False
CMEMS_AREA = True
skill = 0
dt_start_plot_ini = ['20170101']
dt_end_plot_ini = ['20220614']
list_color = ['red']
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
PATH_OUT = PATH_IN+'img/GLO12/oper/'
DATA_IN = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'
SYSTEM = ['GLO12V4']
VAR = ['seaice-concentration','salinity',\
       'temperature', 'sla', 'sst',\
       'zonal-velocity-filtr', 'meridional-velocity-filtr']
#VAR = ['salinity', 'temperature']
if not os.path.isdir(PATH_OUT):
    os.makedirs(PATH_OUT)
#VAR = ['sst']
list_var0 = ['sla','sst','seaice-concentration','zonal-velocity-filtr', 'meridional-velocity-filtr']
list_varTS = ['temperature','salinity']
level_sla_stt = 0
level_t_s = [0, 1, 2, 3, 4]
cla_areaini = params.liste_zone
cla_depth = params.profondeur3
# ~~~~~~~~~~~ Definition des dates ~~~~~~~~~~~~~~~~~

dt_start_plot = "20170101"
dt_end_plot = "20220614"
dateCNESref = d.datetime.strptime('19500101','%Y%m%d').toordinal()
dtst = d.datetime.strptime(dt_start_plot,'%Y%m%d')
dted = d.datetime.strptime(dt_end_plot,'%Y%m%d')


# Lecture des stats pour les differents systemes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

dict={}
dict_tmp = {}

for v, varname in enumerate(VAR):
    dict_tmp[varname] = {} ; dict[varname] = {}

    if varname in list_var0: level = level_sla_stt
    elif varname in list_varTS: level = level_t_s
    else: print ('level not define')
    for s, prod in enumerate(SYSTEM):
        print ('system : %s' %(prod))
        dt_start_plot = dt_start_plot_ini[s]
        dt_end_plot = dt_end_plot_ini[s]
        try:
            file = f'{DATA_IN}{prod}/Stats_GODAE/NETCDF/{depth_comp}'\
                   f'/product_quality_stats_GLOBAL_ANALYSIS_FORECAST_PHY_'\
                   f'{prod}_{dt_start_plot}_{dt_end_plot}.nc'
            print(file)
            #filename = glob(file)[0]
            filename = file
        except Exception as e:
            raise RuntimeError(file) from e
        dict_tmp, dict, area_name, name_ech = \
            read_stats(filename, prod, varname, dict_tmp, dict)
    # ~~ On lisse la courbe en faisant une moyenne glissante des stats sur n jours ~~~
    print ('Filter out the timeserie')
    for s, prod in enumerate(SYSTEM):
        if prod == "PSY4V3R1": prod = "PSY4"
        #if prod == "GLO12V4": prod = "GLO12"
        if prod == "PSY3V3R3": prod = "PSY3"
        for a, area in enumerate(area_name):
            #if area == "Full Domain":
            #if area == "Indian Ocean":
            if 'time' not in dict[varname][prod][area]:
                continue
            v_time = np.array(dict[varname][prod][area]['time'])
            MAT_TMP = np.zeros((len(v_time), 4))
            for t in range(len(v_time)):
                MAT_TMP[t,0] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['rmsd'])[t:t+int(window)])
                MAT_TMP[t,1] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['bias'])[t:t+int(window)])
                MAT_TMP[t,2] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['nb_obs'])[t:t+int(window)])
                MAT_TMP[t,3] = np.nanmedian(np.array(dict_tmp[varname][prod][area]['cor_ano'])[t:t+int(window)])
            dict[varname][prod][area]['rmsd'] = np.sqrt(MAT_TMP[:,0])
            dict[varname][prod][area]['bias'] = MAT_TMP[:,1]
            dict[varname][prod][area]['nb_obs'] = MAT_TMP[:,2]
            dict[varname][prod][area]['cor_ano'] = MAT_TMP[:,3]
            print(f'{area} ok')
        print(f'{prod} {varname} ok')
        print(f'{prod} {varname}')

# ************************************************************************
#             Test pour tracer plusieurs plots simples
# ************************************************************************


SYSTEM = ['GLO12V4']
comp_name = 'vs'.join(SYSTEM)
if SINGLE_PLOT:
    print ("Single_plot")
    if GLO_AREA:
        area_ini = ['Full Domain']
    elif CMEMS_AREA:
        area_ini = area_name
    for area in area_ini:
        print(f'Area {area}')
        a = np.where(np.array(area_name) == area)[0][0]
        for v, varname in enumerate(VAR):
            if varname in list_var0:
                list_prof = [cla_depth[level_sla_stt]]
            elif varname in list_varTS:
                list_prof = cla_depth[level_t_s]
            for prof in list_prof:
                fig, splot, nb_var = tsp.fmtFig(area, name_ech)
                leg = True
                ax_fig = plt.subplot(1,1,1)
                if cla_areaini[a] == 'ARC':
                    f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
                                     dtst, dted, leg, list_color, splot, nb_var, skill)
                else:
                    f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
                                     dtst, dted, leg, list_color, splot, nb_var, skill)
                areavalue = cla_areaini[a].decode("utf-8")
                filename_out = f"{PATH_OUT}{areavalue}_rmsd_bias_"\
                               f"{varname}_{comp_name}_{dt_start_plot}"\
                               f"-{dt_end_plot}_{prof.decode()}.png"
                print(filename_out)
                plt.savefig(filename_out, dpi=200)
                plt.close()


sys.exit(1)
# ************************************************************************
#                Test pour tracer des multiplots
# ************************************************************************
#SYSTEM = ['FOAM','PSY4','ENSMEAN','HYCOM_RTOFS','BLK','CGOFS','GIOPS','CMCC']
SYSTEM = ['FOAM','PSY4','HYCOM_RTOFS','BLK','GIOPS','CMCC']

if MULTI_PLOT == True:
    print ("Multiplot")
    if GLO_AREA:
        area_ini = ['Full Domain']
    elif CMEMS_AREA:
        area_ini = area_name
    for area in area_ini:
        a = np.where(np.array(area_name) == area)[0][0]
        fig, splot, nb_var = tsp.fmtFig(area, name_ech, splot='multi', nb_var=len(VAR))
        leg = False
        for v, varname in enumerate(VAR):
            #if varname in ['sla','sst']: prof = cla_depth[level_sla_stt]
            if varname in ['sla','sst']: prof = "" # cla_depth[level_sla_stt]
            elif varname in ['temperature','salinity']: prof = cla_depth[level_t_s]
            ax_fig = plt.subplot(len(VAR),1,v+1) 
            if (v+1) == len(VAR):
                leg = True
            if cla_areaini[a] == 'ARC':
                f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
                                 dtst, dted, leg, list_color, splot, nb_var, skill)
            else:
                f = tsp.plotStat(fig, ax_fig, dict, varname, area, SYSTEM, prof,
                                 dtst, dted, leg, list_color, splot, nb_var, skill)
        print (str(dt_start_plot),str(type_ech),str(dt_end_plot),str(type_ech))
        if not os.path.exists(PATH_OUT+str(type_ech)+'/'):
            os.makedirs(PATH_OUT+str(type_ech)+'/')
        areavalue = cla_areaini[a].decode("utf-8")
        filename_out = f"{PATH_OUT}{type_ech}/{areavalue}_rmsd_bias_"\
                        f"{comp_name}_{dt_start_plot}-{dt_end_plot}_{type_ech}.png"
        plt.savefig(filename_out, dpi=200)
        plt.close()


