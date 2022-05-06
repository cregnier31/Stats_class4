# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
#!/usr/bin/python
import matplotlib as mpl
import numpy
#style.use('ggplot')
from lib_pyt.filter import filters
from lib_pyt.filter.filters import medfilt
from lib_pyt.loader.loader import Loader

mpl.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as md
from matplotlib.dates import YearLocator, MonthLocator, DateFormatter
from matplotlib.ticker import EngFormatter

import matplotlib.dates as dates
import numpy as np
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
import pandas as pd
from lib_pyt.libtools.sydate import SyDate
from lib_pyt.plot.class_ts import Plot_TS

def get_value(filename, nb_var, ll_filter=False, window=5):
    value1 = np.genfromtxt(filename)
    list_var = []
    for ind_var in range(nb_var):
        var = value1[:,ind_var]
        if ind_var == 0 :
            list_var.append(var)
        else:
            var_filtre1 = medfilt(var[:],window)
            data = pd.Series(var_filtre1)
            var_filtre2 = data.rolling(window, center=True).mean()
            list_var.append(var_filtre2)
    return list_var

def convert_timeBC(time):
    time_ref_1=[]
    for timevar in time:
        time2 = SyDate.fromjulianBC(int(timevar))
        year=str(time2)[0:4]
        month=str(time2)[4:6]
        day=str(time2)[6:8]
        time_ref_1.append(dt.datetime.strptime(str(time2),"%Y%m%d"))
    return time_ref_1

#class Plot_TS_cam(object):
#    def __init__(self, splot='single', nb_var=1, xfontsize=12, fontitle=13, fontweight="bold",
#                  rotation=20, datefmt='%Y-%m', **kwargs):
#        self.plt = plt
#        self.fontweight = fontweight
#        self.fontitle = fontitle
#        self.xfontsize = xfontsize
#        self.rotation = rotation
#        self.datefmt = datefmt
#        if splot == 'single':
#            print('Single plot')
#            self.fig, self.ax = plt.subplots()
#            self.fig = self.plt.figure(figsize = (12,5))
#            self.fig.subplots_adjust(left = 0.06, bottom = 0.14,
#            right = 0.927, top = 0.86, wspace = 0.12, hspace = 0.3)
#        elif splot == 'multi' and nb_var == 4:
#            self.fig = self.plt.figure(figsize = (12,13))
#            fig.subplots_adjust(left = 0.06, bottom = 0.085,
#            right = 0.92, top = 0.92, wspace = 0.12, hspace = 0.3)
#        elif splot == 'multi' and nb_var == 2:
#            self.fig = self.plt.figure(figsize = (12,7))
#            self.fig.subplots_adjust(left = 0.06, bottom = 0.14,
#            right = 0.92, top = 0.89, wspace = 0.12, hspace = 0.3)
#        else:
#            print ('************ config not found ************')
#            sys.exit()
#        self.ax.spines["top"].set_visible(False)
#        self.ax.spines["bottom"].set_visible(True)
#        self.ax.spines["right"].set_visible(False)
#        self.ax.spines["left"].set_visible(True)
#        self.plt.grid(linewidth = 0.5)
#        self.ax0 = self.fig.axes[0]
#        self.ax0.set_xticklabels(self.ax0.get_xticks(), fontsize=xfontsize, rotation=rotation, ha='center')
#        self.ax0.xaxis.set_major_formatter(dates.DateFormatter(datefmt))
#
#    def plot_timeserie(self, title, subtitle, time1, var1, output, nb_obs=None,
#                        color='black', markersize=2, linestyle='-',
#                        label='', marker='None', cmin=None, cmax=None, log=False):
#        if not cmin and not cmax:
#            cmin = np.nanmin(var1)
#            cmax = np.nanmax(var1)
#
#        self.ax0.plot(time1[:], var1[:], linestyle=linestyle,
#                      markersize=markersize,label=label, color=color, marker=marker)
#        self.plt.title(title, fontsize=self.fontitle, fontweight="bold")
#        self.plt.suptitle(subtitle,fontsize=15.5,color='red')
#        datemin = np.datetime64(time1[0])
#        datemax = np.datetime64(time1[-1])
#        #self.plt.ylim(-1, 1)
#        # Plot Zero line
#        self.plt.plot([datemin, datemax], [0,0], color = 'black', linestyle = '--', linewidth = 0.8)
#        self.ax0.set_xlim(datemin, datemax)
#        if nb_obs.any():
#            self.ax1 = self.ax0.twinx()
#            self.ax1.grid(axis='y', color='grey', linestyle='--', alpha=0.5, linewidth = 0.3)
#            self.barlist = self.plt.bar(time1[:], nb_obs[:], alpha=0.14, width=10, linewidth=0, color="grey", label='nb values')
#            self.plt.grid(linewidth = 0.0)
#            if log:
#                self.ax1.set_yscale("log", nonpositive='clip')
#            else:
#                formatter1 = EngFormatter(places=1)
#                self.ax1.yaxis.set_major_formatter(formatter1)
#            self.ax1.tick_params(axis='y', labelcolor='darkgrey',labelsize='small', length=6, pad = 1.5)
#            self.plt.ylabel("Number of observations", fontsize=12,color='darkgrey')
#            self.ax1 = self.ax0.twinx()
#            self.ax1.axes.get_yaxis().set_visible(False)
#            self.ax1.set_xticklabels(self.ax1.get_xticks(), fontsize=self.xfontsize,
#                                     rotation=self.rotation, ha='center')
#            self.ax1.xaxis.set_major_formatter(dates.DateFormatter(self.datefmt))
#        return self
#
#    def overplot(self, time1, var1, color1='black', markersize=2, linestyle='-', label='', marker='None'):
#        self.ax0.plot(time1[:], var1[:], linestyle=linestyle,
#                      markersize=markersize,label=label, color=color1, marker=marker)
#        return self
#
#    def savefig(self, output):
#        print (f"Save output {output}")
#        #self.ax0.legend(loc=1, borderaxespad=0.,prop={'size':8})
#        self.ax0.legend(loc=1, bbox_to_anchor=(0., 0.88, 0.1, 0.1), ncol=1, fontsize = 7, edgecolor = 'black', facecolor = 'white')
#        self.plt.savefig(output) #, bbox_inches="tight")
#        self.plt.close

modele1 = "GLO12V4"
modele1_tmp = "GLO12V4-light"

modele2 = "PSY4V3R1"
list_var = ['TEMP', 'SAL']
list_region = ['ACC', 'ARC', 'GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA', 'NORDSEA', 'FACADE', 'BALTIC']
list_region = ['ACC', 'ARC', 'GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA']
list_region = ['GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA']
#list_region=['ACC','ARC','GLO','IND','MED','NAT','NPA','SAT','SPA','TAT','TPA']

list_prof1 = ['0-50m', '50-100m', '100-150m', '150-200m', '200-300m', '300-400m', '400-500m', '0-500m']
list_prof2 = ['0-5m', '5-100m', '100-300m', '300-800m', '800-2000m', '2000-5000m', '0-5000m']
list_prof3 = ['0-100m', '100-300m', '300-800m', '800-2000m', '0-2000m']
list_prof = {}
list_prof['1'] = list_prof1
list_prof['2'] = list_prof2
list_prof['3'] = list_prof3

fic_dir = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele1+'/Class4_pics'
fic_out1 = fic_dir+'/suivi_rms/CORA5.2/'
fic_dir = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele2+'/Class4_pics'
fic_out2 = fic_dir+'/suivi_rms/alleges/CORA5.2/'
dir_plot = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLO12V4/filter_test/'
varmean = "mean"
length_med=4
for var in list_var:
    for key in list_prof.keys():
        for prof in list_prof[key]:
            for region in list_region:
                file1 = fic_out1 + '/File_ASCII/Fic_ASCII_meanval_' + var + '_' \
                        + region + '_' + modele1_tmp + '_' + prof + '.txt'
                file2 = fic_out2 + '/File_ASCII/Fic_ASCII_meanval_' + var + '_' \
                        + region + '_' + modele2 + '_' + prof + '.txt'
                file3 = fic_out1 + '/File_ASCII/Fic_ASCII_' + var + '_' + region \
                        + '_' + modele1_tmp + '_' + prof + '.txt'
                file4 = fic_out2 + '/File_ASCII/Fic_ASCII_' + var + '_' + region \
                        + '_' + modele2 + '_' + prof + '.txt'
                if file1:
                    print(f"file exist {file1}")
                else:
                    sys.exit(1)
                if file2:
                    print(f"file exist {file2}")
                else:
                    print (f"file doesn't exist {file2}")
                    sys.exit(1)
                time, HDCT1_meandiff, WOA18_meandiff, nb_cumul = get_value(file1,4)
                time_ref_1 = convert_timeBC(time)
                time, HDCT1_rmsdiff, WOA18_rmsdiff, nb_cumul_rmsdiff = get_value(file3,4)
                #print(np.nanmin(HDCT1_meandiff), np.nanmax(HDCT1_meandiff))
                #print(np.nanmin(HDCT1_rmsdiff), np.nanmax(HDCT1_rmsdiff))
                #print(f'{time_ref_1=}')
                time2, HDCT2_meandiff = get_value(file2,2)
                time2, HDCT2_rmsdiff = get_value(file4,2)
                time_ref_2 = convert_timeBC(time2)
                cmin = -1.5
                cmax = 1.5
                subtitle = f'(analysis-obs) RMSE/MeanDiff stats in {var}'
                title = f'{region} {prof}'
                title_img = dir_plot+'Serie_temp_meanrms_'+var+'_'+region+'_'+modele1+'_'+prof+"_filtr.png"
                timeserie = Plot_TS(datefmt='%Y').plot_timeserie(title, time_ref_1, HDCT1_rmsdiff,
                                                title_img, label=modele1, nb_obs=nb_cumul[:],
                                                cmin=cmin, cmax=cmax, subtitle=subtitle, color='red', log=False)
                timeserie =  timeserie.overplot(time_ref_1, HDCT1_meandiff[:], color1='red', linestyle='--')
                timeserie =  timeserie.overplot(time_ref_2, HDCT2_rmsdiff[:], color1='black', label=modele2, linestyle='-')
                timeserie =  timeserie.overplot(time_ref_2, HDCT2_meandiff[:], color1='black', linestyle='--')
                timeserie =  timeserie.overplot(time_ref_1, WOA18_rmsdiff[:], color1='blue', label="WOA18")
                timeserie =  timeserie.overplot(time_ref_1, WOA18_meandiff[:], color1='blue', linestyle='--')
                timeserie.savefig(title_img)
