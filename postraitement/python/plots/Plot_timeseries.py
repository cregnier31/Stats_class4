from sytoolkit.sydate_origin import SyDateOrigin
from sytoolkit.sydate import SyDate
import os,sys,logging
import numpy as np
import matplotlib.pyplot as plt
import re,subprocess,shlex
import netCDF4
from mpl_toolkits.basemap import Basemap
import geojson
from geojson import MultiPoint
import matplotlib as mplib
import json

class Plot_timeseries(object):
    def __init__(self,lonmin,lonmax,latmin,latmax,lon_int,lat_int,**kwargs):
        
       degraded_blue=[(0,0,255),(0,50,255),(0,100,255),(0,125,255),(0,150,255),(0,200,255),\
                     (0,210,255), (0,220,255) ,(0,230,255),(0,240,255) ]
       degraded_red=[(255,0,0),(255,50,50),(255,100,100),(255,125,125),(255,150,150),(255,175,175),\
                    (255,185,185),(255,190,190),(255,195,195),(255,200,200)]
 
       self.degraded_blue_ar=np.array(degraded_blue,dtype=float)/255
       self.degraded_red_ar=np.array(degraded_red,dtype=float)/255
       self.degraded_blue=degraded_blue_ar.tolist()
       self.degraded_red=degraded_red_ar.tolist()

       self.plt.figure(figsize=(12,14))
       self.fig,self.ax = self.plt.subplots()
       self.ax.spines["top"].set_visible(False)    
       self.ax.spines["bottom"].set_visible(True)    
       self.ax.spines["right"].set_visible(False)    
       self.ax.spines["left"].set_visible(True)    
       self.plt.xticks(fontsize=10,rotation=20,ha='center')    
       self.plt.grid()
       self.ax.xaxis.set_major_locator(mdates.YearLocator(1))  
       self.ax.xaxis.set_major_formatter(mdates.DateFormatter('%m/%y'))     #optional formatting 


    def scatter_val(self,lon,lat,val,colormap,cmin,cmax,dot_size,titre,outputfile):
       x,y = self.map(lon,lat)
       self.map.scatter(x,y,dot_size,c=val,cmap=colormap,marker='o',edgecolors='none',vmin=cmin, vmax=cmax,zorder=10)
       self.map.colorbar(pad='8%')
       ax=self.fig.add_axes([0.1,0.1,0.8,0.8])
       ax.set_title(titre)
       self.fig.savefig(outputfile, dpi=self.fig.dpi)
#    def scatter_pos(self,x,y)

