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
#from matplotlib.finance import quotes_historical_yahoo_ochl
from sytoolkit.sydate import SyDate
from sytoolkit.sydate_new import SyDatenew
import numpy as np
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
#sys.path.append('/home/cregnier/SVN/mo/LIB/LIB_PYT/')
#from Class_plot import Plot_map 
#from Loader import *
#import arithm
import pandas as pd
from lib_pyt.filter import filters
from lib_pyt.filter.filters import medfilt
from lib_pyt.loader.loader import Loader
from lib_pyt.libtools.sydate import SyDate


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
list_var=['TEMP','SAL']
#list_region=['ACC','ARC','GLO','IND','MED','NAT','NPA','SAT','SPA','TAT','TPA','NORDSEA','FACADE','BALTIC']
list_region=['ACC','ARC','GLO','IND','MED','NAT','NPA','SAT','SPA','TAT','TPA']
list_prof1=['0-50m','50-100m','100-150m','150-200m','200-300m','300-400m','400-500m','0-500m']
##list_prof1=['0-5m','5-100m','100-300m','300-800m','800-2000m','2000-5000m','0-5000m']
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele1+'/Class4_pics'
year='2007-2016'
fic_out1=fic_dir+'/suivi_rms/'+year+'/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele2+'/Class4_pics'
fic_out2=fic_dir+'/suivi_rms/all/'
type_var='rms'
list_typevar=['mean','rms']
#type_var='mean'
length_med=4
for type_var in list_typevar:
    for var in list_var :
        for prof in list_prof1 :
            for region in list_region :
                if type_var == "mean" :
                    file1=fic_out1+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+region+'_'+modele1+'_'+prof+'.txt'
                    file2=fic_out2+'/File_ASCII/Fic_ASCII_meanval_'+var+'_'+region+'_'+modele2+'_'+prof+'.txt'
                else :
                    file1=fic_out1+'/File_ASCII/Fic_ASCII_'+var+'_'+region+'_'+modele1+'_'+prof+'.txt'    
                    file2=fic_out2+'/File_ASCII/Fic_ASCII_'+var+'_'+region+'_'+modele2+'_'+prof+'.txt'    
                if file1 :
                    print("file exist %s" %(file1))
                else: 
                    print("file doesn't exist %s" %(file1))
                    sys.exit(1)
                if file2 :
                    print("file exist %s" %(file2))
                else: 
                    print("file doesn't exist %s" %(file2))
                    sys.exit(1)
                # Open file
               # value1=Loader().factory('ASCII').read_all(file1)
                value1 = np.genfromtxt(file1)
                print(np.shape(value1))
                print(file1)
                time=value1[:,0]
                HDCT1_diff=value1[:,1]
                WOA13_diff=value1[:,2]
                nb_cumul=value1[:,3]
                WOA13_diff=medfilt(WOA13_diff[:],5)
                data=pd.Series(WOA13_diff)
                #WOA13_diff=pd.rolling_mean(data, window=5, center=True)
                WOA18_diff = data.rolling(5, center=True).mean()
                HDCT1_diff=medfilt(HDCT1_diff[:],5)
                data=pd.Series(HDCT1_diff)
                HDCT1_diff=medfilt(HDCT1_diff[:],5)
                #HDCT1_diff=pd.rolling_mean(data, window=5, center=True)
                HDCT1_diff = data.rolling(5, center=True).mean()
                nb_cumul=medfilt(nb_cumul[:],5)
                data=pd.Series(nb_cumul)
                #nb_cumul=pd.rolling_mean(data, window=5, center=True)
                nb_cumul=medfilt(nb_cumul[:],5)
                nb_cumul = data.rolling(5, center=True).mean()
                time_ref_1=[]
                for timevar in time :
                    time2 = SyDate.fromjulianBC(int(timevar))
                    year=str(time2)[0:4]
                    month=str(time2)[4:6]
                    day=str(time2)[6:8]
                    time_ref_1.append(dt.datetime.strptime(str(time2),"%Y%m%d"))
                print (time_ref_1)
                #print time
                #value2=Loader().factory('ASCII').read_all(file2)
                value2 = np.genfromtxt(file2)
                time2=value2[:,0]
                HDCT2_diff=value2[:,1]
                HDCT2_diff=medfilt(HDCT2_diff[:],5)
                data=pd.Series(HDCT2_diff)
                #HDCT2_diff=pd.rolling_mean(data, window=5, center=True)
                HDCT2_diff = data.rolling(5, center=True).mean()
                time_ref_2=[]
                for timevar in time2 :
                    time2 = SyDate.fromjulianBC(int(timevar))
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
                if type_var == "mean" :
                    plt.ylim(-0.5,0.5)
                    print("mean limit")
                else :
                    plt.ylim(0.0,0.8)
                # Ticks on the right and top of the plot are generally unnecessary chartjunk.    
                ax.get_xaxis().tick_bottom()    
                ax.get_yaxis().tick_left()  
                # Limit the range of the plot to only where the data is.    
                # Avoid unnecessary whitespace.    
                #plt.xlim(0,length_time)
                choice=type_var
                ax.set_xlim(time_ref_1[0],time_ref_1[-1])
                plt.xticks(fontsize=14,rotation=90)    
                ind=0
                ##
                plt.xticks(fontsize=12,rotation=20,ha='center')    
                plt.grid()
                ax.xaxis.set_major_formatter(DateFormatter('%Y%m%d'))
                ax.xaxis.set_major_locator(md.DayLocator())
                ax.fmt_xdata = DateFormatter('%b')
                ax0 = fig.axes[0]
                ax1 = ax0.twinx()
                ax0.grid(axis='y', color='grey', linestyle='-', alpha=0.5)
                barlist=ax1.bar(time_ref_1[:],nb_cumul[:],alpha=0.2,width=10,linewidth=0,color="gray",label='nb values')
                ##barlist[0].set_color('g')
                ax1.set_yscale("log", nonposy='clip')
                ax1.tick_params(axis='y', colors='darkgray')
                plt.ylabel("Number of observations", fontsize=12,color='darkgray')  
                ##
                ax0 = fig.axes[0]
                ax1 = ax0.twinx()
                ax1.axes.get_yaxis().set_visible(False)
                plt.title('(analysis-obs) '+choice.upper()+' error in '+var+' for '+region+' '+prof,fontsize=11)
                if choice == "mean" :
                    print(HDCT1_diff[:])
                    plt.plot_date(time_ref_1[:],HDCT1_diff[:],linestyle='-',marker='None',markersize=2,label=str(modele1), color='black')
                    plt.plot_date(time_ref_1[:],WOA13_diff[:],linestyle='-',marker='None',markersize=2,label='WOA13', color='red')
                    plt.plot_date(time_ref_2[:],HDCT2_diff[:],linestyle='-',marker='None',markersize=2,label=str(modele2), color='blue')
                    xlabel="Mean bias"
                elif choice == "rms" :
                    print('rms')
                    plt.plot_date(time_ref_1[:],HDCT1_diff[:],linestyle='-',marker='None',label=str(modele1), color='black')
                    plt.plot_date(time_ref_1[:],WOA13_diff[:],linestyle='-',marker='None',label='WOA13', color='red')
                    plt.plot_date(time_ref_2[:],HDCT2_diff[:],linestyle='-',marker='None',label=str(modele2), color='blue')
                    xlabel="RMS error"
                plt.legend(loc=1, borderaxespad=0.,prop={'size':8})
                plt.xticks(fontsize=12,rotation=20,ha='center')    
                dir_plot='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/PSY4V3R1/filter/'
                title_img=dir_plot+'Serie_temp_'+type_var+'_'+var+'_'+region+'_'+modele1+'_'+prof+".png"
                plt.savefig(title_img) #, bbox_inches="tight")
                plt.close
                print(title_img)
                sys.exit(1)
