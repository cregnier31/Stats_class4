# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
#!/usr/bin/python
import matplotlib as mpl
from matplotlib import style
import numpy
#style.use('ggplot')

mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as md
from matplotlib.dates import YearLocator, MonthLocator, DateFormatter
from matplotlib.finance import quotes_historical_yahoo_ochl
from sytoolkit.sydate import SyDate
from sytoolkit.sydate_new import SyDatenew
import numpy as np
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
sys.path.append('/home/cregnier/SVN/mo/LIB/LIB_PYT/')
from Class_plot import Plot_map 
from Loader import *
import arithm
import pandas as pd


def medfilt (x, k):
    """Apply a length-k median filter to a 1D array x.
        Boundaries are extended by repeating endpoints.
    """
    assert k % 2 == 1, "Median filter length must be odd."
    assert x.ndim == 1, "Input must be one-dimensional."
    k2 = (k - 1) // 2
    y = np.zeros ((len (x), k), dtype=x.dtype)
    y[:,k2] = x
    for i in range (k2):
        j = k2 - i
        y[j:,i] = x[:-j]
        y[:j,i] = x[0]
        y[:-j,-(i+1)] = x[j:]
        y[-j:,-(i+1)] = x[-1]

    return np.median (y, axis=1)




modele1="PSY4V3R1"
modele2="PSY4V2R2"
list_var=['SST']
#list_region=['ACC','ARC','GLO','IND','MED','NAT','NPA','SAT','SPA','TAT','TPA','NORDSEA','FACADE','BALTIC']
list_region=['ACC','ARC','GLO','IND','MED','NAT','NPA','SAT','SPA','TAT','TPA','BALTIC']
#list_region=['GLO']
list_prof1=['0-0m']
date1='20150101'
date2='20151231'
year='2015'
##list_prof1=['0-5m','5-100m','100-300m','300-800m','800-2000m','2000-5000m','0-5000m']
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele1+'/Stats_GODAE/'
fic_out1=fic_dir+'/File_ASCII/MYO/'+year+'/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele2+'/Stats_GODAE/'
fic_out2=fic_dir+'/File_ASCII/MYO/'+year+'/'
type_var='rms'
#type_var='mean'
length_med=4
for var in list_var :
    for prof in list_prof1 :
        for region in list_region :
            file1=fic_out1+'BasicStats_product_quality_'+modele1+'_'+region+'_'+date1+'_'+date2+'_'+str(var)+'_'+str(prof)+'.txt'
            print file1
            file2=fic_out2+'BasicStats_product_quality_'+modele2+'_'+region+'_'+date1+'_'+date2+'_'+str(var)+'_'+str(prof)+'.txt'
            print file2
            if file1 :
                print "file exist %s" %(file1)
            else: 
                print "file doesn't exist %s" %(file1)
                sys.exit(1)
            if file2 :
                print "file exist %s" %(file2)
            else: 
                print "file doesn't exist %s" %(file2)
                sys.exit(1)
            # Open file
            value1=Loader().factory('ASCII').read_all(file1)
            print np.shape(value1)
            print file1
            time=value1[:,0]
            HDCT1_meandiff=value1[:,3]
            HDCT1_rmsdiff=value1[:,4]
            nb_cumul=value1[:,1]
            ##HDCT1_rmsdiff=medfilt(HDCT1_rmsdiff[:],5)
            ##data=pd.Series(HDCT1_rmsdiff)
            ##HDCT1_rmsdiff=pd.rolling_mean(data, window=5, center=True)
            ##HDCT1_meandiff=medfilt(HDCT1_meandiff[:],5)
            ##data=pd.Series(HDCT1_meandiff)
            ##HDCT1_meandiff=pd.rolling_mean(data, window=5, center=True)
            #nb_cumul=medfilt(nb_cumul[:],5)
            #data=pd.Series(nb_cumul)
            #nb_cumul=pd.rolling_mean(data, window=5, center=True)
            WOA13_rmsdiff=value1[:,5]
            WOA13_meandiff=value1[:,6]
            WOA13_rmsdiff=medfilt(WOA13_rmsdiff[:],5)
            data=pd.Series(WOA13_rmsdiff)
            WOA13_rmsdiff=pd.rolling_mean(data, window=5, center=True)
            time_ref_1=[]
            print time
            for timevar in time :
                print timevar
                #time2 = SyDatenew.fromjulianBC(int(timevar))
                time2 = SyDatenew.fromjulian(int(timevar),'19500101')
                year=str(time2)[0:4]
                month=str(time2)[4:6]
                day=str(time2)[6:8]
                time_ref_1.append(dt.datetime.strptime(str(time2),"%Y%m%d"))
            #print time
            value2=Loader().factory('ASCII').read_all(file2)
            time2=value2[:,0]
            HDCT2_meandiff=value2[:,3]
            HDCT2_rmsdiff=value2[:,4]
            #HDCT2_rmsdiff=medfilt(HDCT2_rmsdiff[:],5)
            #data=pd.Series(HDCT2_rmsdiff)
            #HDCT2_rmsdiff=pd.rolling_mean(data, window=5, center=True)
            #HDCT2_meandiff=medfilt(HDCT2_meandiff[:],5)
            #data=pd.Series(HDCT2_meandiff)
            #HDCT2_meandiff=pd.rolling_mean(data, window=5, center=True)

            time_ref_2=[]
            for timevar in time2 :
                #time2 = SyDatenew.fromjulianBC(int(timevar))
                time2 = SyDatenew.fromjulian(int(timevar),'19500101')
                year=str(time2)[0:4]
                month=str(time2)[4:6]
                day=str(time2)[6:8]
                time_ref_2.append(dt.datetime.strptime(str(time2),"%Y%m%d"))
            ## PLOT
            plt.figure(figsize=(12, 14)) 
            fig,ax = plt.subplots()
            ax = plt.subplot(111)    
            ax.spines["top"].set_visible(False)    
            ax.spines["bottom"].set_visible(True)    
            ax.spines["right"].set_visible(False)    
            ax.spines["left"].set_visible(True)    
#            plt.ylim(-0.8,0.8)
            # Ticks on the right and top of the plot are generally unnecessary chartjunk.    
            ax.get_xaxis().tick_bottom()    
            ax.get_yaxis().tick_left()  
            # Limit the range of the plot to only where the data is.    
            # Avoid unnecessary whitespace.    
            #plt.xlim(0,length_time)
            ax.set_xlim(time_ref_1[0],time_ref_1[-1])
            plt.xticks(fontsize=14,rotation=90)    
            plt.xticks(fontsize=12,rotation=20,ha='center')    
            plt.grid()
            ax.xaxis.set_major_formatter(DateFormatter('%m/%Y'))
            ax.fmt_xdata = DateFormatter('%b')
            ## Plot histogram 
            #ax0 = plt.subplot()
            #ax0 =plt.axes[0]
            # add plot in the same figure
            #ax1 = ax0.twinx()                                                                                                                              
            #move axis
           ## ax0.yaxis.tick_right()
           ## ax1.yaxis.tick_left()
           ## plt.setp(ax1.get_xticklabels(), visible=False)
           ## ax1.grid(axis='y', color='grey', linestyle='-',alpha=0.5)
           ## barlist=ax0.bar(time_ref_1[:],nb_cumul[:],alpha=0.2,width=2,linewidth=0.1,color="gray",label='nb values')
           ## barlist[0].set_color('g')
           ## ax0.set_yscale("log", nonposy='clip')
           ## ax0.tick_params(axis='y', colors='darkgray')
           ## plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
           ## ax0 = fig.axes[0]
           ## ax1 = ax0.twinx()
           ## ax1.axes.get_yaxis().set_visible(False)
            ##ax0 =plt.axes[0]
            ###ax0 = fig.axes[0]
            ##ax1 = ax0.twinx()
            #ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
            #barlist=ax1.bar(time_ref_1[:],nb_cumul[:],alpha=0.2,width=2,linewidth=0.1,color="gray",label='nb values')
            print nb_cumul[:]
##            ##barlist[0].set_color('g')
##            ax1.set_yscale("log", nonposy='clip')
##            ax1.tick_params(axis='y', colors='darkgray')
##            plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
##            ax0 = fig.axes[0]
##            ax1 = ax0.twinx()
##            ax1.axes.get_yaxis().set_visible(False)
            ##
            plt.title('(analysis-obs) Mean and RMS error in '+var+' for '+region+' '+prof,fontsize=11)
            print 'Mean'
            print np.nanmax(HDCT1_meandiff[:])
            print np.nanmin(HDCT1_meandiff[:])
            print 'Rms'
            print np.nanmin(HDCT1_rmsdiff[:])
            print np.nanmax(HDCT1_rmsdiff[:])
            print 'Mean PSY4V2'
            print np.nanmax(HDCT2_meandiff[:])
            print np.nanmin(HDCT2_meandiff[:])
            print 'Rms'
            print np.nanmin(HDCT2_rmsdiff[:])
            print np.nanmax(HDCT2_rmsdiff[:])
            plt.plot_date(time_ref_1[:],HDCT1_meandiff[:],linestyle='--',marker='None',markersize=2,label=str(modele1), color='black')
            plt.plot_date(time_ref_1[:],HDCT1_rmsdiff[:],linestyle='-',marker='None',markersize=2,label=str(modele1), color='black')
            #plt.plot_date(time_ref_1[:],WOA13_diff[:],linestyle='-',marker='None',markersize=2,label='WOA13', color='red')
            plt.plot_date(time_ref_2[:],HDCT2_rmsdiff[:],linestyle='-',marker='None',markersize=2,label=str(modele2), color='blue')
            plt.plot_date(time_ref_2[:],HDCT2_meandiff[:],linestyle='--',marker='None',markersize=2,label=str(modele2), color='blue')
            xlabel="Mean bias/ RMS error"
            plt.legend(loc=1, borderaxespad=0.,prop={'size':8})
            plt.xticks(fontsize=12,rotation=20,ha='center')    
            ## Plot histogram 
            ax0 = plt.subplot()
            # add plot in the same figure
            ax1 = ax0.twinx()
            ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
            barlist=ax1.bar(time_ref_1[:],nb_cumul[:],alpha=0.1,width=1,linewidth=0.1,color="gray",label='nb values')
            barlist[0].set_color('g')
            ax1.set_yscale("log", nonposy='clip')
            ax1.tick_params(axis='y', colors='darkgray')
            plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
            dir_plot='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/PSY4V3R1/SST/'
            title_img=dir_plot+'Serie_temp_'+type_var+'_'+var+'_'+region+'_'+modele1+'_'+prof+".png"
            plt.savefig(title_img) #, bbox_inches="tight")
            plt.close
            print title_img
