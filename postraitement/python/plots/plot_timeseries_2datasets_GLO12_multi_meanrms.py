# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
#!/usr/bin/python
import matplotlib as mpl
import numpy
#style.use('ggplot')
from lib_pyt.filter import filters
from lib_pyt.filter.filters import medfilt
from lib_pyt.loader.loader import Loader

mpl.use('Agg')
from matplotlib.figure import Figure
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
from lib_pyt.plot.class_ts import Plot_TS

def create_gridspec(orient,ncols, nb_fig, nlines, size=1 ):
    """
        Create gridspec depending on lines and columns
    """
    if ncols == 1:
        if orient == 'horiz':
            tab_params = [ size  for ind in range(nb_fig//ncols)]
            tab_params.append(0.05)
            tab_params.append(0)
            gs = gridspec.GridSpec(nlines, ncols, height_ratios=tab_params,
                                    bottom=.03,hspace=0.2, top=.95, wspace=.2)
        else:
            tab_params = [ size  for ind in range(nb_fig//ncols)+1]
            tab_params.append(0)
            gs = gridspec.GridSpec(nlines, ncols, width_ratios=tab_params,
                                    bottom=.03,hspace=0.2, top=.95, wspace=.2)
    else:
        if orient == 'horiz':
            print(f'Horizontal distribution {nb_fig//ncols}')
            tab_params = [ size  for ind in range(nb_fig//ncols)]
            #tab_params.append(0.05)
            #tab_params.append(0)
            #print(tab_params)
            gs = gridspec.GridSpec(nlines, ncols, height_ratios=tab_params,
                                   left=0.05,right=0.95, bottom=.08, hspace=0.25, top=.93, wspace=.25)
           # gs.update(left=0.05,right=0.95, bottom=.08)

        else:
            tab_params_width = [ size  for ind in range(ncols)]
            gs = gridspec.GridSpec(nlines, ncols, width_ratios=tab_params_width,\
                                    bottom=.01,hspace=0.01, top=.95, wspace=.3)
    return gs

def find_pos(ind, nlines, ncols):

    list_pos =[]
    for i in range(nlines):
        for j in range(ncols):
            list_pos.append((i,j))
    return list_pos


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
        if timevar != 0:
            time2 = SyDate.fromjulianBC(int(timevar))
            year=str(time2)[0:4]
            month=str(time2)[4:6]
            day=str(time2)[6:8]
            time_ref_1.append(dt.datetime.strptime(str(time2),"%Y%m%d"))
        else:
            print('Timevar is null!!')
            time_ref_1.append(None)
    return time_ref_1

modele1 = "GLO12V4"
modele1_tmp = "GLO12V4-light"

modele2 = "PSY4V3R1"
list_var = ['TEMP', 'SAL']
list_region = ['ACC', 'ARC', 'GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA', 'NORDSEA', 'FACADE', 'BALTIC']
list_region = ['ACC', 'ARC', 'GLO', 'IND', 'MED', 'NAT', 'NPA', 'SAT', 'SPA', 'TAT', 'TPA']
list_region = ['GLO', 'NAT', 'ARC', 'BALTIC', 'MED', 'TAT', 'SAT', 'ACC', 'IND', 'NPA', 'TPA', 'SPA']
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
dir_plot = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLO12V4/filter_test2/'
varmean = "mean"
length_med = 4
for var in list_var:
    for key in list_prof.keys():
        for prof in list_prof[key]:
            title_img = dir_plot+'Serie_temp_meanrms_'+var+'_multi_'+modele1+'_'+prof+"_filtr.png"
            fig_multi = plt.figure(figsize=(20, 12))
            nb_fig = len(list_region)
            print(nb_fig)
            orientation = "horiz"
            ncols = 4
            if orientation == "vert" or orientation == "horiz":
                nlines = nb_fig//ncols
            else:
                nlines = nb_fig//ncols + 2
            print (nlines)
            size = 1.0
            gs = create_gridspec(orientation, ncols, nb_fig, nlines, size=size)
            i = 0
            j = 0
            print (list_region)
            list_pos = find_pos(nb_fig, nlines, ncols)
            for ind, region in enumerate(list_region[::]):
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
                print(time)
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
                subtitle = f'RMSE/MeanDiff (analysis-obs) stats in {var}  - {prof} -'
                title = f'{region}'
                ax_multi = fig_multi.add_subplot(gs[i,j])
                if  j == ncols-1:
                    timeserie = Plot_TS(datefmt='%Y', ax=ax_multi).plot_timeserie(title, subtitle, time_ref_1, HDCT1_rmsdiff,
                                                    title_img, label=modele1, nb_obs=nb_cumul[:],
                                                    cmin=cmin, cmax=cmax, color='red', log=False, ylabel=True)
                else:
                    timeserie = Plot_TS(datefmt='%Y', ax=ax_multi).plot_timeserie(title, subtitle, time_ref_1, HDCT1_rmsdiff,
                                                    title_img, label=modele1, nb_obs=nb_cumul[:],
                                                    cmin=cmin, cmax=cmax, color='red', log=False, ylabel=False)

                timeserie =  timeserie.overplot(time_ref_1, HDCT1_meandiff[:], color1='red', linestyle='--')
                timeserie =  timeserie.overplot(time_ref_2, HDCT2_rmsdiff[:], color1='black', label=modele2, linestyle='-')
                timeserie =  timeserie.overplot(time_ref_2, HDCT2_meandiff[:], color1='black', linestyle='--')
                timeserie =  timeserie.overplot(time_ref_1, WOA18_rmsdiff[:], color1='blue', label="WOA18")
                timeserie =  timeserie.overplot(time_ref_1, WOA18_meandiff[:], color1='blue', linestyle='--', )

                if ind == 0:
                    fig_multi.legend(loc='lower center', ncol=4, fontsize=12, frameon=False)
                #if ncols == 1: i+=1
                print ('----------------------')
            print(f' Figure {title_img}')
            fig_multi.savefig(title_img)
