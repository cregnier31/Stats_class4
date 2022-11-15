# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4
#!/usr/bin/python
import matplotlib as mpl
import numpy as np
#style.use('ggplot')
import sys,glob,re,os
import netCDF4
import datetime as dt
import time
import pandas as pd
import matplotlib.gridspec as gridspec
import matplotlib.pyplot as plt
from lib_pyt.plot.class_ts import Plot_TS
from lib_pyt.filter import filters
from lib_pyt.filter.filters import medfilt
from lib_pyt.libtools.date_utils import convert_timeBC
from lib_pyt.plot.class_ts import Plot_TS
mpl.use('TkAgg')

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
                                    bottom=.02,hspace=0.2, top=.80, wspace=.2)
    else:
        if orient == 'horiz':
            print(f'Horizontal distribution {nb_fig//ncols}')
            tab_params = [ size  for ind in range(nb_fig//ncols)]
            tab_params.append(0.05)
            tab_params.append(0)
            gs = gridspec.GridSpec(nlines, ncols, height_ratios=tab_params,
                                    bottom=-.1,hspace=0.5, top=.90, wspace=.2)
        else:
            tab_params_width = [ size  for ind in range(ncols)]
            gs = gridspec.GridSpec(nlines, ncols, width_ratios=tab_params_width,\
                                    bottom=.01,hspace=0.01, top=.95, wspace=.3)
    return gs

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


def find_pos(ind, i, j, ncols=2):
    """
       Find position in the gridspec
    """
    if ind > 0:
        if ind%2 == 0:
            i+=1
            j=0
        else:
            j=1
    return i, j

def squiggle_xy(a, b, c, d, i=np.arange(0.0, 2*np.pi, 0.05)):
    return np.sin(i*a)*np.cos(i*b), np.sin(i*c)*np.cos(i*d)

dir_plot = './imgs/'
title_img = dir_plot+'test_multi.png'
list_region=['GLO', 'ACC', 'ARC', 'TPA', 'MED', 'TAT']
fig_multi = plt.figure(figsize=(18, 16))
nb_fig = len(list_region)
ncols = 2
orientation = "horiz"
if orientation == "vert" or orientation == "horiz_man":
    nlines = nb_fig//ncols
else:
    nlines = nb_fig//ncols + 2
size = 1.0
gs = create_gridspec(orientation, ncols, nb_fig, nlines, size=size)
i = 0
j = 0
modele1 = "GLO12V4"
modele1_tmp = "GLO12V4-light"
modele2 = "PSY4V3R1"
fic_dir = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele1+'/Class4_pics'
fic_out1 = fic_dir+'/suivi_rms/CORA5.2/'
fic_dir = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele2+'/Class4_pics'
fic_out2 = fic_dir+'/suivi_rms/alleges/CORA5.2/'
dir_plot = '/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLO12V4/filter_test/'
varmean = "mean"
length_med = 4
var = 'TEMP'
prof = '0-50m'
for ind, region in enumerate(list_region):
    print(ind,region)
    if ncols == 1:
        j = 0
    else:
        i, j = find_pos(ind, i , j, ncols=ncols)

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
    print(np.nanmin(HDCT1_meandiff), np.nanmax(HDCT1_meandiff))
    print(np.nanmin(HDCT1_rmsdiff), np.nanmax(HDCT1_rmsdiff))
    #print(f'{time_ref_1=}')
    #value2=Loader().factory('ASCII').read_all(file2)
    time2, HDCT2_meandiff = get_value(file2,2)
    ax_multi = fig_multi.add_subplot(gs[i,j])
    #ax_multi.plot(*squiggle_xy(ind + 1, ind+2, ind + 3, ind + 4))
    #ax_multi.set(xticks=[], yticks=[])
    cmin = -1.5
    cmax = 1.5
    subtitle = f'(analysis-obs) RMSE/MeanDiff stats in {var}'
    title = f'{region} {prof}'
    timeserie = Plot_TS(ax=ax_multi).plot_timeserie(title, subtitle, time_ref_1, HDCT1_rmsdiff,
                                    title_img, label=modele1, nb_obs=nb_cumul[:],
                                    cmin=cmin, cmax=cmax, color='red')
    print (f'----{i}---{j}-----')

#print(f' Figure {title_img}')
fig_multi.savefig(title_img)
#sys.exit(1)
