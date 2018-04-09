#!/usr/bin/python
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.dates import YearLocator, MonthLocator, DateFormatter
import matplotlib.ticker as plticker
import matplotlib.dates as mdates
import matplotlib.ticker as mtick
import numpy as np
import sys,glob,re,os
import time

class Plot_timeseries(object):
    def __init__(self,dirout,ymin,ymax,**kwargs):

       degraded_blue=[(0,0,255),(0,50,255),(0,100,255),(0,125,255),(0,150,255),(0,200,255),\
                     (0,210,255), (0,220,255) ,(0,230,255),(0,240,255),(0,250,255),(0,252,255) ]
       degraded_red=[(255,0,0),(255,50,50),(255,100,100),(255,125,125),(255,150,150),(255,175,175),\
                    (255,185,185),(255,190,190),(255,195,200),(255,200,200),(255,210,210),(255,220,220)]
       degraded_blue_ar=np.array(degraded_blue,dtype=float)/255
       degraded_red_ar=np.array(degraded_red,dtype=float)/255
       self.degraded_blue=degraded_blue_ar.tolist()
       self.degraded_red=degraded_red_ar.tolist()
       self.dirout=dirout
       plt.figure(figsize=(12,14))
       fig,ax = plt.subplots()
       ax.tick_params(axis='both', which='major', labelsize=10)
       ax.spines["top"].set_visible(False)    
       ax.spines["bottom"].set_visible(True)    
       ax.spines["right"].set_visible(False)    
       ax.spines["left"].set_visible(True)    
       plt.xticks(fontsize=10,rotation=20,ha='center')    
       plt.grid()
       plt.ylim(ymin,ymax)
      # ax.xaxis.set_major_locator(mdates.YearLocator(1))  
       ax.xaxis.set_major_formatter(mdates.DateFormatter('%m/%y'))     #optional formatting 
       ax.fmt_xdata = DateFormatter('%b')
       self.ax=ax
       self.plt=plt
       self.fig=fig

    def plot_TimeSerieswithlead2TS(self,TS1,TS2,TS3,TS4,TS5,TS6,TS7,time1,time2,time3,leadtime,title,ylabel,barlabel,fileout,
                                label1="best",label2="fcst",label3="pers",color1='blue',
                                color2='red',color3='cyan',color4='pink'):
        self.ax.set_xlim([time1[0],time1[-1]])
        self.plt.title(title, fontsize=8)    
        self.plt.ylabel(ylabel, fontsize=12)
        self.plt.plot_date(time1[:],TS1[:],lw=1.,linestyle='-',marker='None',label=label1, color='black') 
        self.plt.plot_date(time1[:],TS4[:],lw=1.,linestyle='-',marker='None',label='', color='black') 
        for lead_time in range(leadtime) :
            if lead_time == 0 : 
                print TS2
                plt.plot_date(time2[:],TS2[:,lead_time],lw=1.,linestyle='-',marker='None',label=label2, color=self.degraded_blue[lead_time])    
                plt.plot_date(time2[:],TS5[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_blue[lead_time])    
                plt.plot_date(time3[:],TS3[:,lead_time],lw=1.,linestyle='-',marker='None',label=label3, color=self.degraded_red[lead_time])    
                plt.plot_date(time3[:],TS6[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_red[lead_time])    
                self.plt.legend(loc=4, borderaxespad=0.,prop={'size':8})
            else :
                plt.plot_date(time2[:],TS2[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_blue[lead_time])    
                plt.plot_date(time2[:],TS5[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_blue[lead_time])    
                plt.plot_date(time3[:],TS3[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_red[lead_time])    
                plt.plot_date(time3[:],TS6[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_red[lead_time])    

        ax0 = self.fig.axes[0]
        ax1 = ax0.twinx()
        ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
        self.plt.plot(time1[:],TS7[:],lw=1.5,linestyle='-',marker='None',color='darkgray')
       # ax1.tick_params(axis='y', colors='darkgray',labelsize='small')
        #ax1.set_yscale("log", nonposy='clip')
        ax1.tick_params(axis='both', which='major', labelsize=5,colors='darkgray')
        self.plt.ylabel("Number of observations", fontsize=10,color='darkgray')  
    #    ax1.set_ylabel('Number of observations',fontsize=10,color='darkgray')
        #barlist=ax1.bar(time1[:],TS7[:],alpha=0.1,width=2,linewidth=0,color="gray",label=barlabel)
        self.plt.savefig(self.dirout+fileout,dpi=150)
        print "Plot output : %s "%(self.dirout+fileout)

    def plot_TimeSerieswithlead(self,TS1,TS2,TS3,TS4,time1,time2,time3,leadtime,title,ylabel,barlabel,fileout,
                                label1="best",label2="fcst",label3="pers",color1='blue',
                                color2='red',color3='cyan',color4='pink'):
        self.ax.set_xlim([time1[0],time1[-1]])
        self.plt.title(title, fontsize=8)    
        self.plt.ylabel(ylabel, fontsize=12)
        self.plt.plot_date(time1[:],TS1[:],lw=1.,linestyle='-',marker='None',label=label1, color='black') 
        for lead_time in range(leadtime) :
            if lead_time == 0 :
                print TS2[:,lead_time]
                plt.plot_date(time2[:],TS2[:,lead_time],lw=1.,linestyle='-',marker='None',label=label2, color=self.degraded_blue[lead_time])    
                plt.plot_date(time3[:],TS3[:,lead_time],lw=1.,linestyle='-',marker='None',label=label3, color=self.degraded_red[lead_time])    
                self.plt.legend(loc=4, borderaxespad=0.,prop={'size':8})
            else :
                print TS2[:,lead_time]
                plt.plot_date(time2[:],TS2[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_blue[lead_time])    
                plt.plot_date(time3[:],TS3[:,lead_time],lw=1.,linestyle='-',marker='None',label='', color=self.degraded_red[lead_time])    

        ax0 = self.fig.axes[0]
        ax1 = ax0.twinx()
        ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
        self.plt.plot(time1[:],TS4[:],lw=1.5,linestyle='-',marker='None',color='darkgray')
       # ax1.tick_params(axis='y', colors='darkgray',labelsize='small')
        #ax1.set_yscale("log", nonposy='clip')
        ax1.tick_params(axis='both', which='major', labelsize=5,colors='darkgray')
        self.plt.ylabel("Number of observations", fontsize=10,color='darkgray')  
        self.plt.savefig(self.dirout+fileout,dpi=150)
        print "Plot output : %s "%(self.dirout+fileout)

    def plot_4TimeSeries(self,TS1,TS2,TS3,TS4,TS5,time1,time2,title,ylabel,barlabel,fileout,
                         label1="best",label2="fcst",label3="best",label4="fcst",color1='blue',
                         color2='red',color3='cyan',color4='pink'):
        self.ax.set_xlim([time1[0],time1[-1]])
        self.plt.title(title, fontsize=12)    
        self.plt.ylabel(ylabel, fontsize=12)  
        self.plt.plot_date(time1[:],TS1[:],lw=1.,linestyle='-',marker='None',label=label1, color=color1) 
        self.plt.plot_date(time2[:],TS2[:],lw=1.,linestyle='-',marker='None',label=label2, color=color2) 
        self.plt.plot_date(time1[:],TS3[:],lw=1.,linestyle='-',marker='None',label=label3, color=color3) 
        self.plt.plot_date(time2[:],TS4[:],lw=1.,linestyle='-',marker='None',label=label4, color=color4) 
        self.plt.legend(loc=4, borderaxespad=0.,prop={'size':8})
        ax0 = self.fig.axes[0]
        ax1 = ax0.twinx()
        ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
        #ax1.set_yscale("log", nonposy='clip')
        barlist=ax1.bar(time1[:],TS5[:],alpha=0.1,width=2,linewidth=0,color="gray",label=barlabel)
        ax1.yaxis.set_major_formatter(mtick.FormatStrFormatter('%.1e'))
        ax1.tick_params(axis='y', colors='darkgray',labelsize='small')
        ax1.set_ylabel('Number of observations',fontsize=10,color='darkgray')
       # self.plt.ylabel("Number of observations", fontsize=10,color='darkgray')  
        self.plt.savefig(self.dirout+fileout,dpi=150)
        print "Plot output : %s "%(self.dirout+fileout)
    def plot_2TimeSeries(self,TS1,TS2,TS3,time1,time2,title,ylabel,barlabel,
                         fileout,label1="best",label2="fcst",color1="black",color2='blue'):
        self.ax.set_xlim([time1[0],time1[-1]])
        self.plt.title(title, fontsize=12)    
        self.plt.ylabel(ylabel, fontsize=12)  
        self.plt.plot_date(time1,TS1[:],lw=1.,linestyle='-',marker='None',label=label1, color=color1) 
        self.plt.plot_date(time2,TS2[:],lw=1.,linestyle='-',marker='None',label=label2, color=color2) 
        self.plt.legend(loc=3, borderaxespad=0.,prop={'size':8})
        ax0 = self.fig.axes[0]
        ax1 = ax0.twinx()
        ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
        barlist=ax1.bar(time1[:],TS3[:],alpha=0.1,width=2,linewidth=0,color="gray",label=barlabel)
        #ax1.set_yscale("log", nonposy='clip')
        ax1.tick_params(axis='y', colors='darkgray')
        ax1.yaxis.set_major_formatter(mtick.FormatStrFormatter('%.1e'))
        ax1.tick_params(axis='y', colors='darkgray',labelsize='small')
        self.plt.ylabel("Number of observations", fontsize=10,color='darkgray')  
        self.plt.savefig(self.dirout+fileout,dpi=150)
        print "Plot output : %s "%(self.dirout+fileout)
    

    def plot_TimeSerie(self,TS1,TS2,time,title,ylabel,barlabel,fileout,label1=""):
        self.ax.set_xlim([time[0],time[-1]])
        self.plt.title(title, fontsize=12)    
        self.plt.ylabel(ylabel, fontsize=12)  
        self.plt.plot_date(time[:],TS1[:],lw=1.,linestyle='-',marker='None',label=label1, color=self.degraded_blue[0]) 
        self.plt.legend(loc=3, borderaxespad=0.,prop={'size':8})
        ax0 = self.fig.axes[0]
        ax1 = ax0.twinx()
        ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
        barlist=ax1.bar(time[:],TS2[:],alpha=0.1,width=10,linewidth=0,color="gray",label=barlabel)
        ax1.set_yscale("log", nonposy='clip')
        ax1.tick_params(axis='y', colors='darkgray')
        self.plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
        ax1.yaxis.set_major_formatter(mtick.FormatStrFormatter('%.1e'))
        ax1.tick_params(axis='y', colors='darkgray',labelsize='small')
        self.plt.savefig(self.dirout+fileout,dpi=150)
        print "Plot output : %s "%(self.dirout+fileout)

