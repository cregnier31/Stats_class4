#!/usr/bin/python
import matplotlib as mpl
#mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as md
from matplotlib.dates import YearLocator, MonthLocator, DateFormatter
from matplotlib.finance import quotes_historical_yahoo_ochl
import matplotlib.ticker as plticker
import matplotlib.dates as mdates
from sytoolkit.sydate import SyDate
import numpy as np
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
sys.path.append('/home/cregnier/DEV/Python/lib/')
from Class_plot import Plot_map 
import arithm

##class Plot_timeseries(object):
##    def __init__(self,dirout,ymin,ymax,**kwargs):
##
##       degraded_blue=[(0,0,255),(0,50,255),(0,100,255),(0,125,255),(0,150,255),(0,200,255),\
##                     (0,210,255), (0,220,255) ,(0,230,255),(0,240,255) ]
##       degraded_red=[(255,0,0),(255,50,50),(255,100,100),(255,125,125),(255,150,150),(255,175,175),\
##                    (255,185,185),(255,190,190),(255,195,195),(255,200,200)]
##       degraded_blue_ar=np.array(degraded_blue,dtype=float)/255
##       degraded_red_ar=np.array(degraded_red,dtype=float)/255
##       self.degraded_blue=degraded_blue_ar.tolist()
##       self.degraded_red=degraded_red_ar.tolist()
##       self.dirout=dirout
##       plt.figure(figsize=(12,14))
##       fig,ax = plt.subplots()
##       ax.spines["top"].set_visible(False)    
##       ax.spines["bottom"].set_visible(True)    
##       ax.spines["right"].set_visible(False)    
##       ax.spines["left"].set_visible(True)    
##       plt.xticks(fontsize=10,rotation=20,ha='center')    
##       plt.grid()
##       plt.ylim(ymin,ymax)
##       ax.xaxis.set_major_locator(mdates.YearLocator(1))  
##       ax.xaxis.set_major_formatter(mdates.DateFormatter('%m/%y'))     #optional formatting 
##       ax.fmt_xdata = DateFormatter('%b')
##       self.ax=ax
##       self.plt=plt
##       self.fig=fig
##
##    def plot_4TimeSeries(self,TS1,TS2,TS3,TS4,TS5,time,title,ylabel,barlabel,fileout,label1="best",label2="fcst",label3="best",label4="fcst"):
##        self.ax.set_xlim([time[0],time[-1]])
##        self.plt.title(title, fontsize=12)    
##        self.plt.ylabel(ylabel, fontsize=12)  
##        self.plt.plot_date(time[:],TS1[:],lw=1.,linestyle='-',marker='None',label=label1, color=self.degraded_blue[0]) 
##        self.plt.plot_date(time[:],TS2[:],lw=1.,linestyle='-',marker='None',label=label2, color=self.degraded_blue[4]) 
##        self.plt.plot_date(time[:],TS3[:],lw=1.,linestyle='-',marker='None',label=label3, color=self.degraded_red[0]) 
##        self.plt.plot_date(time[:],TS4[:],lw=1.,linestyle='-',marker='None',label=label4, color=self.degraded_red[4]) 
##        self.plt.legend(loc=1, borderaxespad=0.,prop={'size':8})
##        ax0 = self.fig.axes[0]
##        ax1 = ax0.twinx()
##        ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
##        barlist=ax1.bar(time[:],TS5[:],alpha=0.1,width=10,linewidth=0,color="gray",label=barlabel)
##        ax1.set_yscale("log", nonposy='clip')
##        ax1.tick_params(axis='y', colors='darkgray')
##        self.plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
##        self.plt.savefig(self.dirout+fileout,dpi=150)
##        print "Plot output : %s "%(self.dirout+fileout)
##
##    def plot_TimeSerie(self,TS1,TS2,time,title,ylabel,barlabel,fileout,label1=""):
##        self.ax.set_xlim([time[0],time[-1]])
##        self.plt.title(title, fontsize=12)    
##        self.plt.ylabel(ylabel, fontsize=12)  
##        self.plt.plot_date(time[:],TS1[:],lw=1.,linestyle='-',marker='None',label=label1, color=self.degraded_blue[0]) 
##        self.plt.legend(loc=1, borderaxespad=0.,prop={'size':8})
##        ax0 = self.fig.axes[0]
##        ax1 = ax0.twinx()
##        ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
##        barlist=ax1.bar(time[:],TS2[:],alpha=0.1,width=10,linewidth=0,color="gray",label=barlabel)
##        ax1.set_yscale("log", nonposy='clip')
##        ax1.tick_params(axis='y', colors='darkgray')
##        self.plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
##        self.plt.savefig(self.dirout+fileout,dpi=150)
##        print "Plot output : %s "%(self.dirout+fileout)


ZONE="ANT"
ZONE="ARC"
model="PSY4V3R1"
#model="GIOPS"
#model="FOAM"
#dateval="2016"
DATE="JFM_2017"
filename1="Stats_"+ZONE+"_"+model+"_"+DATE+"_fcst_boxes.nc"
filename2="Stats_"+ZONE+"_"+model+"_"+DATE+"_pers_boxes.nc"
filename3="Stats_"+ZONE+"_"+model+"_"+DATE+"_best_boxes.nc"
#filename2="timeseries_pers_2015_"+ZONE+"_"+model+".nc"
filedir="/naviti/data5/cregnier/CLASS4_MERCATOR/PSY4V3R1/Stats/"
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
#areas=["Labrador_Sea"]
#degraded_blue=[(0,0,255),(0,50,255),(0,100,255),(0,125,255),(0,150,255),(0,200,255),\
#                 (0,210,255), (0,220,255) ,(0,230,255),(0,240,255) ]
#degraded_red=[(255,0,0),(255,50,50),(255,100,100),(255,125,125),(255,150,150),(255,175,175),\
#              (255,185,185),(255,190,190),(255,195,195),(255,200,200)]
degraded_blue=[(0,0,1),(0,0.2,1),(0,0.4,1),(0,0.5,1),(0,0.6,1),(0,7,1),\
                 (0,75,1), (0,8,1) ,(0,85,1),(0,0.9,1) ]
degraded_red=[(1,0,0),(1,0.2,0.2),(1,0.4,0.4),(1,0.5,0.5),(1,0.6,0.6),(1,0.7,0.7),\
              (1,0.75,0.75),(1,0.8,0.8),(1,0.85,0.85),(1,0.9,0.9)]

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
    #ind_max=7
    ind_max=nb_echeances-1
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
    for lead_time in range(nb_echeances-1) :
        print lead_time
        sort_rms_fcst=[rmsdiff_fcst[lead_time,box,x] for  x in sort_index]
        sort_mean_fcst=[meandiff_fcst[lead_time,box,x] for  x in sort_index]
        sort_rms_pers=[rmsdiff_pers[lead_time,box,x] for  x in sort_index2]
        sort_mean_pers=[meandiff_pers[lead_time,box,x] for  x in sort_index2]
       # print sort_rms_fcst
       # print sort_mean_fcst
       # print sort_rms_pers
       # print sort_mean_pers

        plt.plot_date(sort_time[:],sort_rms_fcst[:],lw=1.,linestyle='-',marker='None',label='fcst', color=degraded_blue[lead_time])    
        #plt.plot_date(sort_time,sort_mean_fcst,lw=1.,linestyle='-',marker='None',label='fcst_'+str(lead_time+1), color='c'))
        plt.plot(sort_time2,sort_rms_pers,lw=1.,linestyle='-',label='pers', color=degraded_red[lead_time])   
        if lead_time == 0 :
            sort_mean_best=[meandiff_best[box,x] for  x in sort_index2]
            sort_rms_best=[rmsdiff_best[box,x] for  x in sort_index2]
            print "Best"
            print sort_mean_best
            print sort_rms_best
            plt.plot_date(sort_time2,sort_mean_best,lw=1.,linestyle='-',marker='None',label='best',color='black')
            if ZONE == "ARC" :
                plt.legend(loc=3, borderaxespad=0.)
            elif ZONE == "ANT" :
                plt.legend(loc=4, borderaxespad=0.)
            plt.plot_date(sort_time2,sort_rms_best,lw=1.,linestyle='-',marker='None',label='best',color='black')
            #sort_nb_values=[nb_values[0,box,x] for  x in sort_index2]
            #plt.plot(sort_time2,sort_nb_values,lw=1.5,linestyle='-',marker='None',color='darkgray')
        plt.plot_date(sort_time,sort_mean_fcst,lw=1.,linestyle='-',marker='None',label='fcst_'+str(lead_time+1),color=degraded_blue[lead_time])
    #    plt.show()
       # print sort_mean_fcst
       #plt.plot(sort_time2,sort_rms_pers,lw=1.,linestyle='-',label='pers_'+str(lead_time+1), color='r')    
        plt.plot(sort_time2,sort_mean_pers,lw=1,linestyle='-',label='pers_'+str(lead_time+1), color=degraded_red[lead_time])    
        print "OK %s" %(ind)
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
    dir_plot='/sortref/calval/DATA_COLOCATIONS/SEAICE/OLA_stats/PSY4/PSY4V3R1/OPER/PLOT/'
    print dir_plot+ZONE+"_zone_"+areas[box]+"_"+model+"_fcst_pers.png"
    plt.savefig(dir_plot+ZONE+"_zone_"+areas[box]+"_"+model+"_fcst_pers.png", bbox_inches="tight",dpi=150)
    print "BOX ok"
