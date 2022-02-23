# -*- coding: utf-8 -*-
import os,re,sys,logging
import numpy as np
import matplotlib
matplotlib.use('TkAgg')
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import netCDF4
sys.path.append('../module/')
import utils
from cmaps import cmaps

system = "PSY4V3R1"
#system = "ENSMEAN"
#system = "FOAM"
#system = "BLK"
#system = "GIOPS"
#system = "HYCOM_RTOFS"
#system = "BIOMER4V1R2"
TYPE = "PHYS"
input_dir="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/"+system+"/Stats_GODAE/BOX/bins2d/MONTHLY_CLIM/11/"
output_dir="./img/"+system+"/test_stats/"
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
datestr="20171101_20201130"

colormap = {}
colormap['CSS'] = "WhiteBlueGreenYellowRed"
colormap['PSS'] = "WhiteBlueGreenYellowRed"
#colormap['rmsd'] = "MO_Blue-Red-greyed_minimum"
#colormap['rmsd'] = "WhiteBlueGreenYellowRed"
#colormap['anomaly corr'] = "WhiteBlueGreenYellowRed"

colormap['CSS'] = "MO_greyed70_middle_rev"
colormap['PSS'] = "MO_greyed70_middle_rev"
colormap['nb_obs'] = "WhiteBlueGreenYellowRed"
stats_to_plot=["stats_SST", "stats_SLA","stats_temperature"] 
tab_cmin = {}
tab_cmax = {}
tab_cmin['stats_sst'] = [-2.0]
tab_cmax['stats_sst'] = [2.0]
tab_cmin['stats_sla'] = [-0.15]
tab_cmax['stats_sla'] = [0.15]
tab_cmin['stats_chl-a'] = [-1.0]
tab_cmax['stats_chl-a'] = [1.0]
tab_cmin['stats_temperature'] = [-2.0,-1.0,-0.8,-0.5,-0.5,-0.3]
tab_cmin['stats_salinity'] = [-0.5,-0.5,-0.3,-0.3,-0.15,-0.1]
tab_cmax['stats_temperature'] = [2.0,1.0,0.8,0.5,0.5,0.3]
tab_cmax['stats_salinity'] = [0.5,0.5,0.3,0.3,0.15,0.1]
tab_cmin['CSS'] = [-1.0,-1.0,-1.0,-1.0,-1.0,-1.0]
tab_cmin['PSS'] = [-0.50,-0.50,-0.50,-0.50,-0.50,-0.50]
tab_cmax['PSS'] = [0.50,0.50,0.50,0.50,0.50,0.50]
tab_cmax['CSS'] = [1.0,1.0,1.0,1.0,1.0,1.0]
tab_cmax['stats_temperature'] = [2.0,1.0,0.8,0.5,0.5,0.3]
tab_cmax['stats_salinity'] = [0.5,0.5,0.3,0.3,0.15,0.1]

region = 'global'

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
#list_variables = filter (lambda x:x.startswith("skill") , nc_file2.variables.keys())
list_variables = filter (lambda x:x.startswith("stats") , nc_file2.variables.keys())
list_stats = nc_file2.variables['metric_names'][:]
area_names = utils.pull_names(list_stats)
print (area_names)
print (list_variables)
sys.exit(1)
depths = nc_file2.variables['depths'][:]
forecasts = nc_file2.variables['forecasts'][:]
if TYPE == "PHYS":
    list_forecasts = ['FRCST1D', 'FRCST3D', 'FRCST5D', 'FRCST7D', 'FRCST9D']
else:
    list_forecasts = ['HDCST','FCST']
list_stats = utils.pull_names(list_stats)
prof=0
frcst=0
proj='PlateCarree_pac'
for variable in list_variables:
    list_dimensions = nc_file2.variables[variable].dimensions
    if 'depths' in list_dimensions:
        nb_depths = len(nc_file2.dimensions['depths'])
    else:
        nb_depths = 1
    for prof in range(nb_depths):
        profvalue = str(depths[prof])
        if prof > 0 :
            bprofvalue = str(depths[prof-1])
        else:
            bprofvalue = "0"
        for frcst,fcst_value in enumerate(list_forecasts):
            for stat in range(len(area_names)):
                print((area_names[stat]))
                if str(area_names[stat]).startswith("PSS_skill_score"):
                    PSS =  nc_file2.variables[variable][frcst,prof,stat,:]
                    PSS = np.where(PSS.mask==True, np.nan, PSS)
                if str(area_names[stat]).startswith("CSS_skill_score"):
                    CSS =  nc_file2.variables[variable][frcst,prof,stat,:]
                    CSS = np.where(CSS.mask==True, np.nan, CSS)
            var_PSS = np.zeros((nlat, nlon))
            var_CSS = np.zeros((nlat, nlon))
            for j in range(nlat):
                for i in range(nlon):
                    valmask  = mask[j,i]
                    var_PSS[j,i] = PSS[valmask-1]
                    var_CSS[j,i] = CSS[valmask-1]
            tab_res = {}
            tab_res['CSS'] = var_CSS
            tab_res['PSS'] = var_PSS
            ## Plot statistics
            for stat in stats_to_plot:
                print ('Plot %s' %(stat))
                titre = "Skill score "+str(fcst_value)+" "+stat+" "+system+' '+variable+' '+bprofvalue+"-"+profvalue+'m for Date '+str(datestr)
                outputfile=output_dir+"/"+system+"_"+str(fcst_value)+'_'+variable+"_"+stat+"_"+profvalue+"m_"+region+'_'+str(datestr)+".png"
                print (variable)
                inter = 0.05
                if stat == "rmsd" or stat == "anomaly corr" or stat == "nb_obs":
                    cmin = 0
                else:
                    cmin =  tab_cmin[stat][prof]
                if stat == "anomaly corr":
                    cmax = 1.0
                elif stat == "nb_obs":
                    cmax = np.nanpercentile(tab_res[stat], 95)
                else:
                    cmax =  tab_cmax[stat][prof]
                ## Cartopy implementation
                if stat != "nb_obs":
                    map().pcolor(lon, lat, tab_res[stat], colormap=colormap[stat], title=titre,\
                                         proj=proj, cmin=cmin, cmax=cmax, inter=inter,\
                                         output=outputfile, units=stat, show=False, labelfont=16, cbfont=16, titlefont=12)
