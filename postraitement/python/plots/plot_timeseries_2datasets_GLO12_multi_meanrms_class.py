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
from lib_pyt.libtools.sydate import SyDate
import numpy as np
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
import pandas as pd
import matplotlib.gridspec as gridspec
from matplotlib.figure import Figure

from lib_pyt.plot.class_ts import Plot_TS
from lib_pyt.plot.class_multiplot import multiTS

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

modele1 = "GLO12V4"
modele1_tmp = "GLO12V4-light"

modele2 = "PSY4V3R1"
list_var = ['TEMP', 'SAL']
list_region = ['ACC', 'ARC', 'GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA', 'NORDSEA', 'FACADE', 'BALTIC']
list_region = ['ACC', 'ARC', 'GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA']
list_region = ['GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA','ACC', 'ARC','BALTIC']
list_region = ['GLO', 'NAT', 'ARC', 'BALTIC', 'MED', 'TAT', 'SAT', 'ACC', 'IND', 'NPA', 'TPA', 'SPA']
list_prof1 = ['0-50m', '50-100m', '100-150m', '150-200m', '200-300m', '300-400m', '400-500m', '0-500m']
list_prof2 = ['0-5m', '5-100m', '100-300m', '300-800m', '800-2000m', '2000-5000m', '0-5000m']
list_prof3 = ['0-100m', '100-300m', '300-800m', '800-2000m', '0-2000m']
list_prof = {}
list_prof['1'] = list_prof1
list_prof['2'] = list_prof2
list_prof['3'] = list_prof3
nb_plots = 4

fic_dir = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele1+'/Class4_pics'
fic_out1 = fic_dir+'/suivi_rms/CORA5.2/'
fic_dir = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele2+'/Class4_pics'
fic_out2 = fic_dir+'/suivi_rms/alleges/CORA5.2/'
dir_plot = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLO12V4/RUN2/GLO12vsPSY4/'
varmean = "mean"
length_med = 4
for var in list_var:
    for key in list_prof.keys():
        for prof in list_prof[key]:
            title_img = dir_plot+'Serie_temp_meanrms_'+var+'_multi_'+modele1+'_'+prof+"_filtr.png"
            orientation = "horiz"
            fig_multi = multiTS(orientation)
            nb_fig = len(list_region)
            ncols = 4
            size = 1.0
            gs = fig_multi.create_gridspec(orientation, ncols, nb_fig, size=size)
            list_pos = fig_multi.find_pos(nb_fig, fig_multi.nlines, ncols)
            for ind, region in enumerate(list_region[::-1]):
                subtitle = f'RMSE/MeanDiff (analysis-obs) stats in {var}  - {prof} -'
                title = f'{region}'
                #fig_multi.fig.title(title, fontsize=12, fontweight="bold")
                #fig_multi.fig.suptitle(subtitle, fontsize=15.5, color='red')
                i, j  = list_pos[ind]
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
                time, HDCT1_rmsdiff, WOA18_rmsdiff, nb_cumul_rmsdiff = get_value(file3,4)
                ll_none = False
                if np.all((time == 0)):
                    time[time == 0] = np.nan
                    time_ref_1 = np.nan
                    ll_none = True
                else:
                    time_ref_1 = convert_timeBC(time)
                time2, HDCT2_meandiff = get_value(file2,2)
                time2, HDCT2_meandiff = get_value(file2,2)
                time2, HDCT2_rmsdiff = get_value(file4,2)
                if np.all((time2 == 0)):
                    print('Only None value')
                    time2[time2 == 0] = np.nan
                    time_ref_2 = time2
                else:
                    time_ref_2 = convert_timeBC(time2)
                if not ll_none:
                    cmin = -1.5
                    cmax = 1.5
                    ax_multi = fig_multi.fig.add_subplot(gs[i,j])
                    if  j == ncols-1:
                        timeserie = Plot_TS(datefmt='%Y', ax=ax_multi).plot_timeserie(title, time_ref_1, HDCT1_rmsdiff,
                                                        title_img, label=modele1, nb_obs=nb_cumul[:],
                                                        cmin=cmin, cmax=cmax, color='red', log=False, ylabel=True)
                    else:
                        timeserie = Plot_TS(datefmt='%Y', ax=ax_multi).plot_timeserie(title, time_ref_1, HDCT1_rmsdiff,
                                                        title_img, label=modele1, nb_obs=nb_cumul[:],
                                                        cmin=cmin, cmax=cmax, color='red', log=False, ylabel=False)

                    timeserie =  timeserie.overplot(time_ref_1, HDCT1_meandiff[:], color1='red', linestyle='--')
                    timeserie =  timeserie.overplot(time_ref_2, HDCT2_rmsdiff[:], color1='black', label=modele2, linestyle='-')
                    timeserie =  timeserie.overplot(time_ref_2, HDCT2_meandiff[:], color1='black', linestyle='--')
                    timeserie =  timeserie.overplot(time_ref_1, WOA18_rmsdiff[:], color1='blue', label="WOA18")
                    timeserie =  timeserie.overplot(time_ref_1, WOA18_meandiff[:], color1='blue', linestyle='--', )

                    if ind == 0:
                        fig_multi.fig.suptitle(subtitle, fontsize=15.5, color='red')
                        fig_multi.fig.legend(loc='lower center', ncol=nb_plots, fontsize=12, frameon=False)
                        #fig_multi.fig.legend(loc='lower center', ncol=4, fontsize=12, frameon=False)
                    print ('----------------------')
            print(f' Figure {title_img}')
            fig_multi.fig.savefig(title_img)
