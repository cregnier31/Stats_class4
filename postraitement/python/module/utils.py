# Module with utilities
import numpy as np
import sys
import pandas as pd
#import matplotlib
#matplotlib.use('Agg')
#from matplotlib import pyplot as plt
#from Class_plot import Plot_map
import datetime as dt

__version__ = 0.1
__date__ = "February 2019"
__author__ = "C.REGNIER"

def pull_names(name_data):
    """
        Convenient name retrieval function
    """
    names = []
    if isinstance(name_data, np.ma.masked_array):
        for letters in name_data:
            value = b''.join(letters.data).strip().decode("utf-8")
            #names.append(str(b''.join(letters.data)).strip())
            names.append(value)
    else:
        for letters in name_data:
            value = b''.join(letters).strip().decode("utf-8")
            names.append(value)
            #names.append(str(b''.join(letters)).strip())
    return names

def echeance(fcst, nf):
    """
       Find lead time
    """
    num_ech = np.where(fcst == nf)[0][0]
    if nf == 0:
        name_ech = 'Hindcast'
    else:
        name_ech = 'Forecast '+str(nf)+' hours'
    return num_ech, name_ech


def plot(iobs, rla_lonobs, rla_latobs, region, log):
    """
        Function to plot selected data
    """
    log.info("Plot region %s " %(region))
    area_names_arc = ['North Pole', 'Queen Elis Is', 'Beaufort Sea', 'Chuckchi Sea',
                      'Siberian Sea', 'Laptev Sea', 'Kara Sea', 'Barents Sea', 'Greenland Sea', 'Stheast Greenland', 'Bafin Bay',
                                                          'Hudson Bay', 'Labrador Sea', 'Bering Sea', 'Okhotsk Sea', ' Baltic Sea']
    area_names_ant = ['Weddel Sea', 'Southern Atlantic Ocean', 'Southern Indian Ocean', 'Southern West Pacific Ocean',
                      'Southern East Pacific Ocean', 'Ross Sea', 'Admundsen Sea', 'Bellingshausen Sea']

    rla_lonobs =  np.where(rla_lonobs>180,rla_lonobs-360,rla_lonobs)
    value = rla_lonobs[:].copy()
    value[:] = 1.0
    lon_inter = 20
    lat_inter = 20
    zone = "GLO"
    proj = "cyl_pac"
    if region in area_names_arc:
        proj = "npstere"
        zone = "Arctic2"
    if region in area_names_ant:
        zone = "Antarctic"
        proj = "spstere"
    #colormap = plt.cm.coolwarm
    #titre = 'Points in '+region+" with matplotlib meth"
    #outputfile = "Selected_points_"+region+".png"
    #colormap = plt.cm.coolwarm
    #cmin = 0
    #cmax = 1
    #dpi = 75
    #font = 16
    #dot_size = 2.0
    #log.info("Plot Map")
    #Plot_map(rla_lonobs[iobs].tolist(), rla_latobs[iobs].tolist(), zone, lon_inter, lat_inter, proj,\
    #        dpi, font).scatter_val(value[iobs].tolist(), colormap, cmin, cmax, dot_size, titre, outputfile)

def compute_last_day_month(y,m):
    return (dt.date(y+int(m/12),m%12+1,1)-dt.date(y,m,1)).days

def find_index_month(date):
    dateval = pd.to_datetime(date)
    index = dateval.month
    return index

