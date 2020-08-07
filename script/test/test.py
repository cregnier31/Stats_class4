# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
import os,sys,string,shutil,glob,re
## Import specific python_modules
sys.path.append('../python_modules/')
import logging
import resource
## Import local modules
import datetime as dt
from datetime import date
from dateutil import relativedelta
from  Logger import Logger
from Utils import *
#for serialization 
import cPickle
#for interpolation
from scipy.spatial import cKDTree
from NetcdReader import *
from netCDF4 import Dataset
from Loader import *
from sytoolkit.sydate import SyDate

# ===============
# LOGGER
# ===============
# Set level of logger
level=1
log=Logger("TEP_CLASS4").run(level)


file_SST="/scratch/work/tranchantb/INPUT_MICROWAT_SST/Microwat_6.9GHz_Orbite_1day_20080102_SST.nc"
file_mod="/scratch/work/tranchantb/PSY4_RUN_FREE_FOR_SST/NEW/PSY4V3R1_1hAV_20080102_20080103_gridT_R20080109.nc"
file_coloc='/scratch/work/smer883/class4/PSY4V3R1/ssthf//coloc/Microwat_6.9GHz_Orbite_1day_20080102_SST_Kdtree_PGN_idw1pt.p'
file_mask="/scratch/work/smer883/static/PSY4V3R1_mask.nc"
coordinates='/scratch/work/smer883/static/PSY4V3R1_mask.nc'

lon_mod,lat_mod=Loader.factory('PGN_coords').read_pos(coordinates)
lon_flat=lon_mod.flatten()
lat_flat=lat_mod.flatten()
lon_resize=lon_flat.reshape(lon_mod.shape)
nc = Dataset(file_SST,'r')
variable = 'longitude'
lon = nc.variables[variable][:]
variable = 'latitude'
lat = nc.variables[variable][:]
juld= nc.variables[variable][:]
n_profiles=len(lon[:])
## Optional Read juld
#print np.shape(lon_flat)
#print np.shape(lon_resize)
#sys.exit(1)
#time_mod=np.ndarray(shape=(12,),dtype=float, order='F')
#for i in range(12):
#    print i 
#sys.exit(1)

f = file(file_coloc, 'r')
zip_var=cPickle.load(f)
d,inds_idw=zip(*zip_var)
d1=np.array(d)
inds_idw1=np.array(inds_idw)
f.close
i=0
for ind in inds_idw1 :
    #indx=np.where(lon_mod[0,:]==lon)
    #indy=np.where(lat_mod[:,0]==lat)
    lon_2=lon_flat[ind]
    lat_2=lat_flat[ind]
    indx = np.argmin(np.abs(lon_mod[0,:]-lon_2))
    indy = np.argmin(np.abs(lat_mod[:,0]-lat_2))
    #log.info("lon mod %f "%(lon_mod[indy,indx]))
    #log.info("lat mod %f "%(lat_mod[indy,indx]))
    #log.info("lon %f "%(lon[i]))
    #log.info("lat %f"%(lat[i]))
    rd_distlon=float(lon_mod[indy,indx])-float(lon[i])
    rd_distlat=float(lat_mod[indy,indx])-float(lat[i])
    rl_max=5.0
    if lat[i] > 60 :
        if np.abs(float(lon_mod[indy,indx])-float(lon[i])) > rl_max or np.abs(float(lat_mod[indy,indx])-float(lat[i])) > rl_max :
            log.error("probleme distance")
            log.error("lon mod %f"%(lon_mod[indy,indx]))
            log.error("lat mod %f"%(lat_mod[indy,indx]))
            log.error("lon %f"%(lon[i]))
            log.error("lat %f"%(lat[i]))
            log.error("dist lon %f"%(rd_distlon))
            log.error("dist lat %f"%(rd_distlat))
            sys.exit(1)
    #julian=juld[i]
    #index_time = np.argmin(np.abs(np.array(liste_date)-julian))
    ##if not np.isnan(indx) and not np.isnan(indy) and not np.isnan(index_time) :
    ##    interp[i]=value_mod[index_time,indy,indx] 
    i+=1
print "OK"


sys.exit(1)

