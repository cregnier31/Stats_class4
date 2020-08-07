# -*- coding: utf-8 -*-
import os,re,sys,logging
import numpy as np
import matplotlib
matplotlib.use('TkAgg')
#matplotlib.use('Agg')
import matplotlib.pyplot as plt
import netCDF4
#from Class_plot_test import Plot_map
sys.path.append('./src/lib-pyt/')
from Class_plot_cartopy import Plot_map_cartopy as map
sys.path.append('../module/')
import utils
from cmaps import cmaps
path = "/home/cregnier/SVN/mo/LIB/LIB_PYT/statics/palettes/"
cmaps(path)
system = "PSY4V3R1"
system = "FOAM"
system = "BLK"
system = "GIOPS"
system = "HYCOM_RTOFS"
system = "ENSMEAN"
#system = "BIOMER4V1R2"
TYPE = "PHYS"
input_dir="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/"+system+"/Stats_GODAE/BOX/bins2d/GODAE/"
output_dir="./img/"+system+"/GODAE/"
#output_dir="./img/"+system+"/"
if not os.path.isdir(output_dir):
    os.makedirs(output_dir)
if system == "PSY4V3R1":
    system2 = "001_024"
    TYPE = "PHYS"
elif system == "PSY3V3R3":
    system2 = "PSY3V3R3"
    TYPE = "PHYS"
elif system == "BIOMER4V1R2":
    system2 = "001_014"
    TYPE = "BIO"
else:
    system2 = system
## Define parameters
datestr="20170101_20171231"
datestr="20180101_20181231"
datestr="20170101_20171231"
datestr="20150101_20151231"
datestr="20160101_20161231"
datestr="20180101_20181231"

colormap = {}
colormap['misfit'] = "MO_greyed70_middle_rev"
colormap['rmsd'] = "MO_Blue-Red-greyed_minimum"
#colormap['rmsd'] = "WhiteBlueGreenYellowRed"
colormap['anomaly corr'] = "WhiteBlueGreenYellowRed"
colormap['nb_obs'] = "WhiteBlueGreenYellowRed"
stats_to_plot=["misfit", "rmsd", "anomaly corr", "nb_obs"] 
tab_cmin = {}
tab_cmax = {}
tab_inter = {}
tab_cmin['stats_sst'] = [-2.0]
tab_cmax['stats_sst'] = [2.0]
tab_cmin['stats_sla'] = [-0.15]
tab_cmax['stats_sla'] = [0.15]
tab_cmin['stats_chl-a'] = [-1.0]
tab_cmax['stats_chl-a'] = [1.0]
tab_cmin['stats_temperature'] = [-2.0,-1.0,-0.8,-0.5,-0.5,-0.3]
tab_cmin['stats_salinity'] = [-0.25,-0.25,-0.2,-0.1,-0.15,-0.1]
tab_cmax['stats_temperature'] = [2.0,1.0,0.8,0.5,0.5,0.3]
tab_cmax['stats_salinity'] = [0.25,0.25,0.2,0.2,0.15,0.1]

tab_inter['stats_temperature'] = [0.05,0.02,0.01,0.01,0.01,0.01,0.01]
tab_inter['stats_salinity'] = [0.01,0.01,0.005,0.005,0.005,0.005,0.005]
tab_inter['stats_sst'] = [0.05,0.02,0.01,0.01,0.01,0.01,0.01]
tab_inter['stats_sla'] = [0.01,0.01,0.01,0.01,0.01,0.01,0.01]
region = 'global'

if system == "PSY4V3R1":
    fileName=input_dir+"glob_mean_quality_stats_GLOBAL_ANALYSIS_FORECAST_"+TYPE+"_"+system2+"_"+datestr+".nc"
else:
    fileName=input_dir+"glob_mean_quality_stats_GLOBAL_ANALYSIS_FORECAST_"+system2+"_"+datestr+".nc"

print (fileName)
filegrid="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/static/mask_bins2deg.nc"
nc_file  = netCDF4.Dataset(str(filegrid),'r')
lon = nc_file.variables['longitude'][:,:]
lat = nc_file.variables['latitude'][:,:]
mask = nc_file.variables['mask'][:,:]
nlat, nlon = np.shape(lon)
nc_file.close()
nc_file2 = netCDF4.Dataset(str(fileName),'r')
list_variables = filter (lambda x:x.startswith("stats") , nc_file2.variables.keys())
list_stats = nc_file2.variables['metric_names'][:]
area_names = utils.pull_names(list_stats)
print (area_names)
depths = nc_file2.variables['depths'][:]
forecasts = nc_file2.variables['forecasts'][:]
if TYPE == "PHYS":
    if len(forecasts) == 10:
        list_forecasts = ['HDCST', 'FRCST1D', 'FRCST3D', 'FRCST5D', 'FRCST7D',\
                'FRCST9D', 'PERS1D', 'PERS3D', 'PERS5D', 'PERS7D', 'PERS9D', 'CLIM']
    else:
        list_forecasts = ['HDCST', 'FRCST1D', 'FRCST3D', 'FRCST5D', \
                           'PERS1D', 'PERS3D', 'PERS5D', 'CLIM']
else:
    list_forecasts = ['HDCST','FCST']
list_stats = utils.pull_names(list_stats)
prof=0
frcst=0
proj='PlateCarree'
proj='PlateCarree_pac'
#proj='Robinson'
#proj='Robinson_pac'
for variable in list_variables:
    list_dimensions = nc_file2.variables[variable].dimensions
    if 'depths' in list_dimensions:
        nb_depths = len(nc_file2.dimensions['depths'])
    else:
        nb_depths = 1
    print (depths)
    for prof in range(nb_depths):
        profvalue = str(depths[prof])
        if prof > 0 :
            bprofvalue = str(depths[prof-1])
        else:
            bprofvalue = "0"
        for frcst,fcst_value in enumerate(list_forecasts):
           # prof_dimensions =
            for stat in range(len(area_names)):
                print((area_names[stat]))
                if str(area_names[stat]).startswith("number of data values"):
                    nb_prof= nc_file2.variables[variable][frcst,prof,stat,:]
                    nb_prof = np.where(nb_prof.mask==True, np.nan, nb_prof)
                if str(area_names[stat]).startswith("mean of reference"):
                    mean_obs =  nc_file2.variables[variable][frcst,prof,stat,:]
                    mean_obs = np.where(mean_obs.mask==True, np.nan, mean_obs)
                if str(area_names[stat]).startswith("mean of product"):
                    mean_mod =  nc_file2.variables[variable][frcst,prof,stat,:]
                    mean_mod = np.where(mean_mod.mask==True, np.nan, mean_mod)
                if str(area_names[stat]).startswith("mean squared error"):
                    msd =  nc_file2.variables[variable][frcst,prof,stat,:]
                    msd = np.where(msd.mask==True, np.nan, msd)
                if str(area_names[stat]).startswith("anomaly correlation"):
                    corr =  nc_file2.variables[variable][frcst,prof,stat,:]
                    corr = np.where(corr.mask==True, np.nan, corr)
                if str(area_names[stat]).startswith("rms diff cumul"):
                    msd_cumul=nc_file2.variables[variable][frcst,prof,stat,:]
                    msd_cumul = np.where(msd_cumul.mask==True, np.nan, msd_cumul)
            ## Create 2D stats
            misfit = np.ma.filled(np.ma.masked_array((mean_obs-mean_mod),np.isnan(mean_obs-mean_mod)), fill_value=np.nan)
            var_misfit = np.zeros((nlat, nlon))
            var_rmsd = np.zeros((nlat, nlon))
            var_rmsd_2 = np.zeros((nlat, nlon))
            var_nbobs = np.zeros((nlat, nlon))
            var_corr = np.zeros((nlat, nlon))
            for j in range(nlat):
                for i in range(nlon):
                    valmask  = mask[j,i]
                    var_misfit[j,i] = misfit[valmask-1]
                    var_corr[j,i] = corr[valmask-1]
                    if ~ np.isnan(np.array(msd[valmask-1])):
                        var_rmsd[j,i] = np.sqrt(msd[valmask-1])
                    else:
                        var_rmsd[j,i] = msd[valmask-1]
            tab_res = {}
            tab_res['misfit'] = var_misfit
            tab_res['rmsd'] = var_rmsd
            tab_res['anomaly corr'] = var_corr
            tab_res['nb_obs'] = var_nbobs
            ## Plot statistics
            for stat in stats_to_plot:
                print ('Plot %s' %(stat))
                titre = "Stat "+str(fcst_value)+" "+stat+" "+system+' '+variable+' '+bprofvalue+"-"+profvalue+'m for Date '+str(datestr)
                outputfile=output_dir+"/"+system+"_"+str(fcst_value)+'_'+variable+"_"+stat+"_"+profvalue+"m_"+region+'_'+str(datestr)+".png"
                print (variable)
                if stat == "rmsd" or stat == "anomaly corr" or stat == "nb_obs":
                    cmin = 0
                else:
                    cmin =  tab_cmin[variable][prof]
                if stat == "anomaly corr":
                    cmax = 1.0
                elif stat == "nb_obs":
                    cmax = np.nanpercentile(tab_res[stat], 95)
                else:
                    cmax =  tab_cmax[variable][prof]
                    if stat == "rmsd":
                        if variable == "stats_sst" or variable == "stats_temperature":
                            cmax = cmax
                        elif variable == "stats_sla":
                            cmax = 0.4
                        else:
                            cmax = cmax*2

                inter = tab_inter[variable][prof]
                ## Cartopy implementation
                if stat != "nb_obs":
                    map().pcolor(lon, lat, tab_res[stat], colormap=colormap[stat], title=titre,\
                                         proj=proj,cmin=cmin, cmax=cmax, inter=inter,\
                                         output=outputfile, units="", show=False, labelfont=16, cbfont=16, titlefont=8)
