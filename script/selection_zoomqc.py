#!/usr/bin/env python
#-*- coding: utf-8 -*-
# C.REGNIER 
## December 2016
### Program to extract files for a design area and with the qc function activated 
import sys
sys.path.append('../python_modules/')
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
lon_min=-79
lon_max=-72
lat_min=-47
lat_max=-41
data_format='NC_CORIO'
data_type='profile'
data_origin='CORIOLIS'
dirtmp="/homelocal-px/px-116/cregnier/tmp/CORIO/CHILI/"
ind=1
il_sum=len(gb("/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/data/OPER/ARMOR/*.nc"))
print il_sum
for fichier in gb("/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/data/OPER/ARMOR/*.nc") :
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
