#!/usr/bin/python
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as md
from matplotlib.dates import YearLocator, MonthLocator, DateFormatter
from matplotlib.finance import quotes_historical_yahoo_ochl
from sytoolkit.sydate import SyDate
import numpy as np
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
sys.path.append('/home/cregnier/DEV/Python/lib/')
from Class_plot import Plot_map 
import arithm
#ZONE="ANT"
ZONE="ARC"
model="PSY4V2R2"
#model="GIOPS"
#model="FOAM"
#dateval="2016"
filename1="Stats_"+ZONE+"_"+model+"_fcst_boxes.nc"
filename2="Stats_"+ZONE+"_"+model+"_pers_boxes.nc"
filename3="Stats_"+ZONE+"_"+model+"_best_boxes.nc"
#filename2="timeseries_pers_2015_"+ZONE+"_"+model+".nc"
filedir="/sortref/calval/DATA_COLOCATIONS/SEAICE/CLASS4_stats/"+model+"/boxes/"
print str(filedir+filename1)
## Read file
nc_file=netCDF4.Dataset(str(filedir+filename1),'r')
nc2_file=netCDF4.Dataset(str(filedir+filename2),'r')
nc3_file=netCDF4.Dataset(str(filedir+filename3),'r')
#nc_attrs, nc_dims, nc_vars = ncdump(nc_file)
dims = [dim for dim in nc_file.dimensions]
length_time=len(nc_file.dimensions['time_counter'])
nb_echeances=len(nc_file.dimensions['z'])
boxes=len(nc_file.dimensions['box'])
time_tab= nc_file.variables['time_counter'][:]
time_tab_pers= nc2_file.variables['time_counter'][:]
time_tab2=[]
for timevar in time_tab:
    time2 = SyDate.fromjulian(int(timevar/86400)+1)
    #print time2
    year=str(time2)[0:4]
    month=str(time2)[4:6]
    day=str(time2)[6:8]
    time_tab2.append(dt.datetime.strptime(str(time2),"%Y%m%d"))

time_tab3=[]
for timevar in time_tab_pers:
    time2 = SyDate.fromjulian(int(timevar/86400)+1)
    #print time2
    year=str(time2)[0:4]
    month=str(time2)[4:6]
    day=str(time2)[6:8]
    time_tab3.append(dt.datetime.strptime(str(time2),"%Y%m%d"))

meandiff_fcst = nc_file.variables['mean'][:,:,:]
rmsdiff_fcst = nc_file.variables['rms'][:,:,:]
print np.shape(rmsdiff_fcst)
nb_values=nc_file.variables['nb_values'][:,:,:]
print np.shape(nb_values)
meandiff_pers = nc2_file.variables['mean'][:,:,:]
rmsdiff_pers= nc2_file.variables['rms'][:,:,:]
meandiff_best = nc3_file.variables['mean'][:,:]
rmsdiff_best= nc3_file.variables['rms'][:,:]
areas=["North_Pole","Queen Elis_Is","Beaufort_Sea","Chuckchi_Sea", \
        "Siberian_Sea","Laptev_Sea","Kara_Sea","Barents_Sea","Greenland_Sea",\
        "Stheast_Greenland","Bafin_Bay","Hudson_Bay","Labrador_Sea","Bering_Sea","Okhotsk_Sea","Baltic_Sea"]
#nb_values = nc_file.variables[''][:,:]

#degraded_blue=[(0,0,255),(0,50,255),(0,100,255),(0,125,255),(0,150,255),(0,200,255)]
degraded_blue=[(0,0,255),(0,50,255),(0,100,255),(0,125,255),(0,150,255),(0,200,255),\
                 (0,210,255), (0,220,255) ,(0,230,255),(0,240,255) ]
degraded_red=[(255,0,0),(255,50,50),(255,100,100),(255,125,125),(255,150,150),(255,175,175),\
              (255,185,185),(255,190,190),(255,195,195),(255,200,200)]
#degraded_red=[(255,0,0),(255,50,50),(255,100,100),(255,125,125),(255,150,150),(255,175,175)]

tableau20 = [(31, 119, 180), (174, 199, 232), (255, 127, 14), (255, 187, 120),    
             (44, 160, 44), (152, 223, 138), (214, 39, 40), (255, 152, 150),    
             (148, 103, 189), (197, 176, 213), (140, 86, 75), (196, 156, 148),    
             (227, 119, 194), (247, 182, 210), (127, 127, 127), (199, 199, 199),    
             (188, 189, 34), (219, 219, 141), (23, 190, 207), (158, 218, 229)]

degraded_blue_ar=np.array(degraded_blue,dtype=float)/255
degraded_red_ar=np.array(degraded_red,dtype=float)/255
degraded_blue=degraded_blue_ar.tolist()
degraded_red=degraded_red_ar.tolist()
tableau20_arr=np.array(tableau20,dtype=float)/255
tableau20=tableau20_arr.tolist()
#tableau20 = np.array[(r/255, g/255, b/255) for r, g, b in tableau20]
print type(tableau20)
missing_val=np.nan
for box in range(boxes):
    plt.figure(figsize=(12, 14)) 
    # Remove the plot frame lines. They are unnecessary chartjunk.    
    fig,ax = plt.subplots()
    #ax = plt.subplot(111)    
    ax.spines["top"].set_visible(False)    
    ax.spines["bottom"].set_visible(True)    
    ax.spines["right"].set_visible(False)    
    ax.spines["left"].set_visible(True)    
    #if model== "GIOPS" : 
    if ZONE == "ARC" :
        plt.ylim(-0.8, 0.8)
    elif ZONE == "ANT" :
        plt.ylim(-0.8, 0.8)
    ax.set_xlim(time_tab2[0],time_tab2[-1])
    plt.xticks(fontsize=14,rotation=90)    
    ind=0
    ind_max=7
    ##if model== "GIOPS" : 
    ##    ind_max=nb_echeances
    ###print np.where(np.isnan(meandiff_fcst[0,:]))[0][0]
    ##elif model== "FOAM" :
    ##    ind_max=7
    ##else :
    ##    ind_max=np.where(np.isnan(meandiff_fcst[0,:]))[0][0]
    
    plt.ylabel("Bias/RMS", fontsize=12)  
    time_tab=np.linspace(1.,length_time,num=length_time)
    sort_index = np.argsort(time_tab2[:])
    sort_time=[time_tab2[x] for x in sort_index]
    
    sort_index2 = np.argsort(time_tab3[:])
    sort_time2=[time_tab3[x] for x in sort_index2]
    print min(sort_time)
    plt.title(ZONE+" zone : RMS error and Mean diff in "+areas[box]+" between AMSR2 ice conc and "+model+" 1-"+str(ind_max)+"D", fontsize=12)    
    for lead_time in range(nb_echeances) :
        sort_rms_fcst=[rmsdiff_fcst[lead_time,box,x] for  x in sort_index]
        sort_mean_fcst=[meandiff_fcst[lead_time,box,x] for  x in sort_index]
        sort_rms_pers=[rmsdiff_pers[lead_time,box,x] for  x in sort_index2]
        sort_mean_pers=[meandiff_pers[lead_time,box,x] for  x in sort_index2]
        plt.plot_date(sort_time[:],sort_rms_fcst[:],lw=1.,linestyle='-',marker='None',label='fcst', color=degraded_blue[lead_time])    
        #plt.plot_date(sort_time,sort_mean_fcst,lw=1.,linestyle='-',marker='None',label='fcst_'+str(lead_time+1), color='c'))
        plt.plot(sort_time2,sort_rms_pers,lw=1.,linestyle='-',label='pers', color=degraded_red[lead_time])    
        if lead_time == 0 :
            sort_mean_best=[meandiff_best[box,x] for  x in sort_index2]
            sort_rms_best=[rmsdiff_best[box,x] for  x in sort_index2]
            print np.shape(sort_rms_best)
            print np.shape(sort_time)
            plt.plot_date(sort_time2,sort_mean_best,lw=1.,linestyle='-',marker='None',label='best',color='black')
            if ZONE == "ARC" :
                plt.legend(loc=3, borderaxespad=0.)
            elif ZONE == "ANT" :
                plt.legend(loc=4, borderaxespad=0.)
            plt.plot_date(sort_time2,sort_rms_best,lw=1.,linestyle='-',marker='None',label='best',color='black')
            #sort_nb_values=[nb_values[0,box,x] for  x in sort_index2]
            #plt.plot(sort_time2,sort_nb_values,lw=1.5,linestyle='-',marker='None',color='darkgray')
        plt.plot_date(sort_time,sort_mean_fcst,lw=1.,linestyle='-',marker='None',label='fcst_'+str(lead_time+1),color=degraded_blue[lead_time])
        print sort_mean_fcst
       #plt.plot(sort_time2,sort_rms_pers,lw=1.,linestyle='-',label='pers_'+str(lead_time+1), color='r')    
        plt.plot(sort_time2,sort_mean_pers,lw=1,linestyle='-',label='pers_'+str(lead_time+1), color=degraded_red[lead_time])    
        ind=ind+1
    
    ax.xaxis.set_major_formatter(DateFormatter('%b%y'))
    ax.set_xlim([sort_time[0],sort_time[-1]])
    ax.fmt_xdata = DateFormatter('%b')
    plt.xticks(fontsize=12,rotation=None,ha='left')    
    plt.grid()
    ax0 = fig.axes[0]
    ax1 = ax0.twinx()
    ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
    sort_nb_values=[nb_values[0,box,x] for  x in sort_index]
    plt.plot(sort_time,sort_nb_values,lw=1.5,linestyle='-',marker='None',color='darkgray')
    ax1.set_yscale("log", nonposy='clip')
    plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
    dir_plot='/home/cregnier/DEV_naviti/CLASS4_aice/plot/img/new/'+model+'/areas/'
    print dir_plot
    plt.savefig(dir_plot+ZONE+"_zone_"+areas[box]+"_"+model+"_fcst_pers.png") #, bbox_inches="tight")
