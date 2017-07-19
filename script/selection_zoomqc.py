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
##for fichier in gb("/naviti/data5/cregnier/GLORYS2V4/data/*.nc") :
##    #print fichier
###    if fichier  == "/naviti/data5/cregnier/GLORYS2V4/data/CO_DMQCGL01_19971211_PR_OC_MERC.nc" : 
##    if fichier  == "/naviti/data5/cregnier/GLORYS2V4/data/CO_DMQCGL01_20040415_PR_OC_MERC.nc" :
##        print ind
##    ind=ind+1
#print ind
#sys.exit(1)
il_sum=66552
ind=1
for fichier in gb("/naviti/data5/cregnier/GLORYS2V4/data/*.nc") :
    log.info('fichier %s ' % (fichier))
    if ind >= 18271 :
        #log.info('Do qc and zoom %i %i ' % (do_qc,zoom)) 
        selector=Selector(data_format,data_type,lon_min,lon_max,lat_min,lat_max).factory(data_origin)
        [new_position,list_index]=selector.run(fichier,zoom,do_qc,data_origin,qc_level)
        if list_index : 
            selector.write(fichier,list_index,dirtmp)
        else :
            log.info('No position find in %s for the zoom ' % (fichier))
            continue
  #  log.info('fichier traité %i %i ' % (ind,il_sum)) 
    print 'fichier traité %i %i ' % (ind,il_sum) 
    ind=ind+1
