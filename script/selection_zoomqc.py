#!/usr/bin/env python
#-*- coding: utf-8 -*-
# C.REGNIER 
## December 2016
### Program to extract files for a design area and with the qc function activated 
from QCcontrol import QCcontroller
import logging,sys,os
from  Logger import Logger
from glob import glob as gb
from Selector import Selector

# ===============
# LOGGER
# ===============
# Set level of logger
level=4
log=Logger("QC_profile").run(level)
qc_level=1  ## flag assim 
zoom=1 # flag zoom 
do_qc=1 # flag qc
lon_min=-180
lon_max=180
lat_min=55
lat_max=90
data_format='NC_CORIO'
data_type='profile'
data_origin='CORIOLIS'
dirtmp="/homelocal-px/px-137/cregnier/tmp/CORIO/"
ind=1
il_sum=len(gb("/naviti/data5/cregnier/GLORYS12V1/*.nc"))
print il_sum
for fichier in gb("/naviti/data5/cregnier/GLORYS2V4/data/*.nc") :
    log.info('fichier %s ' % (fichier))
    selector=Selector(data_format,data_type,lon_min,lon_max,lat_min,lat_max).factory(data_origin)
    [new_position,list_index]=selector.run(fichier,zoom,do_qc,data_origin,qc_level)
    if list_index : 
        selector.write(fichier,list_index,dirtmp)
    else :
        log.info('No position find in %s for the zoom ' % (fichier))
        continue
    log.info('fichier traité %i %i ' % (ind,il_sum)) 
    ind=ind+1
