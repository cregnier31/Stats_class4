#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
# History  : Juillet 2014  : Creation C.REGNIER 
#            Novembre 2014 :  Ajout différentes échéances pour l'interpolation + clims + gestion enchaînement des runs
#            Decembre 2014 :  MAJ pour le cas particulier du zoom
## Description : 
## New CLASS4 launcher to compute CLASS4 with CLASS4 coming from GODAE, ARMOR, CORIOLIS
#
from __future__ import generators
import os,sys,string,shutil,glob,re
sys.path.append("/home/modules/versions/64/fc18/ipython/ipython-1.1/lib/python2.7/site-packages")
sys.path.append("/home/modules/versions/64/fc18/netcdf4-python/netcdf4-python-1.0.7/lib64/python2.7/site-packages/")
sys.path.append("/home/cregnier/python/module/")
sys.path.append("/home/cregnier/python/module/geojson-1.0.7/")
sys.path.append("/home/cregnier/python/module/lib/python2.6/site-packages/")
sys.path.append("/home/cregnier/python/module/lib/python2.7/site-packages/")
sys.path.append("/home/cregnier/python/module/lib/python2.7/site-packages/nco-0.0beta-py2.7.egg/")
import logging
import resource
from Selector import Selector
from Writer import Writer
from Extractor import Extractor
from NmlCreator import NmlCreator
from array import array
from Designer import Designer_file as Design
import operator,getopt
import shelve
import subprocess,shlex
import itertools
import datetime as dt
from datetime import date
from dateutil import relativedelta
from  Logger import Logger
from Sorter import Sorter
import gzip
from Utils import *
#for serialization 
import cPickle
#for interpolation
from scipy.spatial import cKDTree

from NetcdReader import *
from netCDF4 import Dataset

## Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

#sys.path.append("/home/cregnier/DEV/Python/NEW_CL4/")
from Loader import *
from sytoolkit.sydate_origin import SyDateOrigin
from sytoolkit.sydate import SyDate

# ===============
# LOGGER
# ===============
# Set level of logger
level=1
log=Logger("TEP_CLASS4").run(level)

# =============================================================================
#  PART-1 -  Load input parameters and file
# =============================================================================
log.info('========================================================')
log.info('          Load input options and parameter file         ') 
log.info('========================================================')

# ===========================================
# Load options and compute date interval
# ===========================================
[date1,date2,confname,data_type,daterun,cl_schedule,cl_src,nb_proc,cl_typemod]=Loader().factory('INPUT').load(sys.argv[1:],level)
log.error("Nombre de proc %i" %(nb_proc))
log.info("Type des fichiers d'entree %s " %(cl_typemod))
log.info("Schedule %s " %(cl_schedule))
log.info("Dates %s %s " %(date1,date2))
log.info("Daterun %s " %(daterun))
# ==================================
#   Load db configuration file
# ==================================
CONF_PATH=os.getcwd()
#CONF_PATH="/home/cregnier/SVN/mo/TEP_CLASS4_V3/script"
filename = [CONF_PATH+'/'+confname]
print filename
param_dict=Loader.factory('NML').load(filename,level)
nb_level=int(param_dict.get('GLOBAL','LEVELS'))
zoom=int(param_dict.get('GLOBAL','zoom'))
write_geojson=int(param_dict.get('GLOBAL','write_geojson'))
qc_level=int(param_dict.get('GLOBAL','qc_level'))
do_qc=int(param_dict.get('GLOBAL','do_qc'))
do_sort=int(param_dict.get('GLOBAL','do_sort'))
do_decomp=int(param_dict.get('GLOBAL','do_decomp'))
model_type=param_dict.get('GLOBAL','MODELTYPE')
dirdata=param_dict.get('input_dir', 'INPUTDATA')
dirmodel=param_dict.get('input_dir', 'DATA_IN')
data_format=param_dict.get('input_dir', 'DATA_FMT')
dirwork=param_dict.get('output_dir', 'DIRTMP')
diroutput=param_dict.get('output_dir', 'DIROUTPUT')
homedir=param_dict.get('GLOBAL','DIRHOME')
dirtmp=dirwork+'ext-'
prefix_data=param_dict.get('input_dir','PREFIX')
nml_dir=param_dict.get('GLOBAL','NAMELIST_DIR')
daily_pref=param_dict.get('GLOBAL','DAILY_PREF')
direxec=param_dict.get('GLOBAL','EXEDIR')
data_origin=param_dict.get('input_dir','DATA_ORIGIN')
cl_config=param_dict.get('GLOBAL','CONFIGURATION')
#template=cl_config+'_'+model_type
cl_config_h=re.sub("QV","V",cl_config) 
template=cl_config_h+'_'+model_type.lower()
lead_time=param_dict.get('input_dir','LEAD_TIME').split()
lead_int=param_dict.get('input_dir','LEAD_INT').split()
coloc_rep=param_dict.get('output_dir','DIRCOLOC')
dir_log=param_dict.get('GLOBAL','DIRLOG')
gridtemp=param_dict.get('GLOBAL','gridtemp')
gridsal=param_dict.get('GLOBAL','gridsal')
type_run=param_dict.get('GLOBAL','TYPE_RUN')
varname=param_dict.get('GLOBAL','variable')

## Create Output and tmp directory if doesn't exist
if not os.path.exists(dirwork):
    log.info("Workdir %s" %(dirwork))
    os.makedirs(dirwork)
if not os.path.exists(diroutput):
    os.makedirs(diroutput)
if not os.path.exists(coloc_rep):
    os.makedirs(coloc_rep)
if write_geojson  : 
    log.info("Write Geojson file")
    ## Db file for extracted positions
    file_db='CLASS4_shelf.db'
    file_db2='Coloc_CLASS4_shelf.db'
    ## Clean old db
    if (os.path.isfile(file_db)) :
        os.remove(file_db)
    ## Clean old db
    if (os.path.isfile(file_db2)) :
        os.remove(file_db2)
# =============================================================================
# PART 1-bis : DO SORT if not available
# =============================================================================
if do_sort : 
    log.info('              Sort Values for interp               ') 
    sort_rep=param_dict.get('input_dir','DATA_SORT')
    schedule=param_dict.get('GLOBAL','SCHEDULE')
    file_template=cl_config+'_'+daily_pref+'_'
    if schedule == "WEEKLY" :
        Sorter().run_weekly(lead_time,lead_int,date1,date2,daterun,file_template,gridtemp,gridsal,dirmodel,sort_rep)
    elif schedule == "DAILY" :
        Sorter().run_daily(lead_time,lead_int,date1,date2,file_template,dirmodel,sort_rep)
    else :
        log.error("Schedule not valid")
        sys.exit(1)
else :
    sort_rep=dirmodel  

# =============================================================================
#  PART-2 -  DATE Selection and extraction
# =============================================================================
if zoom or data_origin == 'GODAE' : 
    log.info('========================================================')
    log.info('              DATE Selection and extraction             ') 
    log.info('========================================================')
    log.info('Prefix  %s ' %(prefix_data))
    log.info('Prefix  %s %s %s ' %(date1,date2,dirdata))
    log.info('Prefix  %s %s %s' %(dirwork,data_type,template))
    dirstatic=param_dict.get('static','dir_static')
    list_files=Extractor().factory(prefix_data).run(date1,date2,dirdata,dirwork,data_type,template)
elif do_decomp : 
    print 'do decomp'
    print prefix_data
    print date1,date2,dirdata,dirwork,data_type,template,prefix_data
    list_files=Extractor().factory(prefix_data).run(date1,date2,dirdata,dirwork,data_type,template,prefix_data)
else :
    log.info('========================================================')
    log.info('              DATE Selection and extraction  %s         ' %(prefix_data)) 
    log.info('========================================================')
    list_files=Extractor().factory(prefix_data).run_list(date1,date2,dirwork)

if not list_files : 
    log.error('Missing files')
    sys.exit(1)
else :
    log.info('List Files  %s ' % (list_files))

# =============================================================================
#  PART-3 - Area Selection and QC selection
# =============================================================================
log.info('========================================================')
log.info('              Area and QC Selection                     ') 
log.info('========================================================')

if zoom or do_qc : 
    lon_min=int(param_dict.get('GLOBAL','LONMIN'))
    lon_max=int(param_dict.get('GLOBAL','LONMAX'))
    lat_min=int(param_dict.get('GLOBAL','LATMIN'))
    lat_max=int(param_dict.get('GLOBAL','LATMAX'))
    log.info("Inside zoom :  %s %s %s %s " %(lon_min,lon_max,lat_min,lat_max))
list_filepos=[]
ll_file_ok=None
ll_uniq=None
valeurj=date1
coordinates=param_dict.get('static','fic_coordinates')

while valeurj.__ge__(date1) and valeurj.__le__(date2) :
    log.info('Interp day  %s ' % (SyDate.__str__(valeurj))) 
    dateval=SyDate.__str__(valeurj)
    valeurj=valeurj.goforward(1)
    ## Selection of the data
    matching = [s for s in list_files if dateval in s]
    if not matching :
        log.info('Matching  error')
        sys.exit(1)
    for fichier in matching: 
        log.info('Fichier  %s ' % (fichier)) 
        ll_file_interp=None
        # Read position of profiles
        if do_qc or zoom : 
            if zoom : log.info("REGIONAL MODE => AREA SELECTION ") 
            log.info('Do qc and zoom %i %i ' % (do_qc,zoom)) 
            selector=Selector(data_format,data_type,lon_min,lon_max,lat_min,lat_max).factory(data_origin)
            [new_position,list_index]=selector.run(fichier,zoom,do_qc,data_origin,qc_level)
            if list_index : 
                selector.write(fichier,list_index,dirtmp)
                file_new='ext-'+os.path.basename(fichier)
                os.remove(fichier)
                fichier=dirwork+file_new
                lon,lat,obs_value=Loader.factory(data_format).read_pos_and_value(fichier)
                xt, yt, zt = lon_lat_to_cartesian(lon, lat)
            else :
                os.remove(fichier)
                log.info('No position find in %s for the zoom ' % (fichier))
                ll_file_interp=False
                continue	
        else :
            # Case Global without qc
            log.info("GLOBAL MODE => SELECT ALL ") 
            lon,lat,obs_value=Loader.factory(data_format).read_pos_and_value(fichier)
            xt, yt, zt = lon_lat_to_cartesian(lon, lat)
            print "Data origin %s" %(data_origin)
            selector=Selector(data_format,data_type).factory(data_origin)
        # =============================================================================
        # PART-4 - Colocations of positions
        # =============================================================================
        log.info('==========================================')
        log.info('               Coloc Files                ') 
        log.info('==========================================')
        ll_coloc=False
        file_coloc_tmp=os.path.basename(fichier)
        file_coloc_tmp=re.sub('.nc','_Kdtree_PGN_idw4pt.p',file_coloc_tmp)
        file_coloc=coloc_rep+file_coloc_tmp
        if os.path.isfile(file_coloc) : 
            ll_coloc=True
            log.info('coloc existe %s '  %(file_coloc))
            log.info('load existing tree')
         ##   f = file(file_coloc, 'r')
         ##   zip_var=cPickle.load(f)
         ##   d,inds_idw=zip(*zip_var)
         ##   d1=np.array(d)
         ##   inds_idw1=np.array(inds_idw)
         ##   f.close
         ##   print "read ok"
        if not ll_coloc :
            log.info('Coordinates %s ' %(coordinates))
            lon_mod,lat_mod=Loader.factory('PGN_coords').read_pos(coordinates)
            print "coloc don't exist => coloc with KDtree"
            xs, ys, zs = lon_lat_to_cartesian(lon_mod.flatten(), lat_mod.flatten())
            print "Create CKDTREE object"
            sys.exit(1)
            tree = cKDTree(zip(xs, ys, zs))
            print "inverse distance weighting approach"
            d1, inds_idw1 = tree.query(zip(xt, yt, zt), k = 4)
            print "create tree ok"
            f = file(filename1, 'wb')
            cPickle.dump(zip(d1,inds_idw1),f,protocol=cPickle.HIGHEST_PROTOCOL)
            print "dump ok"
            f.close
            ll_tree=True
        ## Compute the weigths
       # w = 1.0 / d1**2 
        ## Create matrix
        nb_obs=int(np.shape(lat)[0])
        log.info('Number obs to coloc %i ' % (nb_obs)) 
        ##pers_tab=np.ndarray(shape=(nb_obs,1,10,1),dtype=float, order='F')
        ##fcst_tab=np.ndarray(shape=(nb_obs,1,10,1),dtype=float, order='F')
        ##pers_tab[:,:,:,:]=9999.
        ##fcst_tab[:,:,:,:]=9999.
        # =============================================================================
        # PART-5 - Compute interpolation
        # =============================================================================
        log.info('=======================================================')
        log.info('               Compute interpolation                   ')
        log.info('=======================================================')
        for time in lead_time : 
            log.info('Lead Time  %s ' % (time)) 
            lead_fin=[]
            lead_new=lead_int
            sort_rep=dirmodel  
            cl_config_use = cl_config
            if  time == 'forecast' : 
                lead_new=[time[0]+time[4]+time[6:8]+element for element in lead_new ]
                lead_fin=lead_new
            elif time == 'persistence' :
                if filter(lambda x: 'best_weekly' in x, lead_time)  :
                    lead_fin=['pers']
                else :
                    lead_tmp=['nwct']
                    lead_new=[time[:4]+element for element in lead_new[1:] ]
                    lead_tmp.extend(lead_new)
                    lead_fin=lead_tmp
            elif time == 'best_estimate' :
                    cl_config_use = re.sub('Q','',cl_config)
                    lead_fin=['hdct']
                    log.info('Lead fin %s ' % (lead_fin)) 
            elif time == 'best_weekly' :
                 lead_fin=['hdct','nwct']
            else : 
                log.error('Lead time %s not expected ' %(time))
            config_d=re.sub("V","QV",cl_config) 
            ## Find and Load the good file
            for directory in lead_fin :
                modele=cl_config_use
                log.info('directory %s' %(directory))
                log.info('model %s' %(modele))
                if directory == 'hdct' :
                    dirmodel_new=dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
                else :
                    dirmodel_new=dirmodel+"DAILY/"+modele[:5]+"/"+modele.lower()+"/"
                print dirmodel_new+directory+"/"+modele+"_"+daily_pref+"_"+dateval+"*_icemod*.nc"
                list_file=glob.glob(dirmodel_new+directory+"/"+modele+"_"+daily_pref+"_"+dateval+"*_icemod*.nc")
                if not list_file :
                    log.error("File missing for %s" %(directory))
                    sys.exit(1)
                log.info('dirmodel  %s ' % (dirmodel)) 
                log.info('directory and file  %s %s ' % (directory,list_file[0])) 
                ## Netcdf value
                fichier=str(list_file[0])
                fc = Dataset(fichier)
                if data_type == 'aice' or 'SLA' :
                    print "Read 3D"
                    print "Varname %s " %(varname)
                    varname='ileadfra'
               #     value_mod = fc.variables[str(varname)][0,:,:]
                    print "load dataset ok"
                    #rla_var=NetcdReader().read_3D(fichier,varname)
                else :
                    value_mod = fc.variables[varname][:,:,:,:]
                ## Do the interp
               # interp_idw = np.sum(w * value_mod.flatten()[inds_idw1], axis=1) / np.sum(w, axis=1)
                log.info('Interp ok ') 

sys.exit(1)
for fichier in list_files: 
    #ll_writepos=None
    log.info('Fichier  %s ' % (fichier)) 
    ll_file_interp=None
    # Read position of profiles
    if do_qc or zoom : 
        if zoom : log.info("REGIONAL MODE => AREA SELECTION ") 
        log.info('Do qc and zoom %i %i ' % (do_qc,zoom)) 
        selector=Selector(data_format,data_type,lon_min,lon_max,lat_min,lat_max).factory(data_origin)
        [new_position,list_index]=selector.run(fichier,zoom,do_qc,data_origin,qc_level)
        if list_index : 
            selector.write(fichier,list_index,dirtmp)
            file_new='ext-'+os.path.basename(fichier)
            os.remove(fichier)
            fichier=dirwork+file_new
            ll_file_ok=True
            ll_file_interp=True
        else :
            os.remove(fichier)
            log.info('No position find in %s for the zoom ' % (fichier))
            ll_file_interp=False
            continue	
            #break	
    else :
        # Case Global without qc
        log.info("GLOBAL MODE => SELECT ALL ") 
        lon,lat,obs_value=Loader.factory(data_format).read_pos_and_value(fichier)
        xt, yt, zt = lon_lat_to_cartesian(lon, lat)
        print "Data origin %s" %(data_origin)
        selector=Selector(data_format,data_type).factory(data_origin)
        ll_file_ok=True
        ll_file_interp=True
    # =============================================================================
    # PART-4 - Colocations of positions
    # =============================================================================
    log.info('==========================================')
    log.info('               Coloc Files                ') 
    log.info('==========================================')
    ll_coloc=False
    file_coloc=coloc_rep+"Kdtree_PGN_idw4pt_"+dateval+".p"
    if os.path.isfile(file_coloc) : 
        ll_coloc=True
        print "coloc existe %s " %(file_coloc)
        print "load existing tree"
        ##f = file(file_coloc, 'r')
        ##zip_var=cPickle.load(f)
        ##d,inds_idw=zip(*zip_var)
        ##d1=np.array(d)
        ##inds_idw1=np.array(inds_idw)
        ##f.close
        print "read ok"
    if not ll_coloc :
        log.info('Coordinates %s ' %(coordinates))
        lon_mod,lat_mod=Loader.factory('PGN_coords').read_pos(coordinates)
        print "coloc don't exist => coloc with KDtree"
        xs, ys, zs = lon_lat_to_cartesian(lon_mod.flatten(), lat_mod.flatten())
        print "Create CKDTREE object"
        sys.exit(1)
        tree = cKDTree(zip(xs, ys, zs))
        print "inverse distance weighting approach"
        d1, inds_idw1 = tree.query(zip(xt, yt, zt), k = 4)
        print "create tree ok"
        f = file(filename1, 'wb')
        cPickle.dump(zip(d1,inds_idw1),f,protocol=cPickle.HIGHEST_PROTOCOL)
        print "dump ok"
        f.close
        ll_tree=True
    ## Compute the weigths
    #w = 1.0 / d1**2 
    ##
    ## Create matrix
    nb_obs=np.shape(lat)
    pers_tab=np.ndarray(shape=(nb_obs,1,10,1),dtype=float, order='F')
    fcst_tab=np.ndarray(shape=(nb_obs,1,10,1),dtype=float, order='F')
    pers_tab[:,:,:,:]=9999.
    fcst_tab[:,:,:,:]=9999.
    # =============================================================================
    # PART-5 - Compute interpolation
    # =============================================================================
    log.info('=======================================================')
    log.info('               Compute interpolation                   ')
    log.info('=======================================================')
    for time in lead_time : 
        log.info('Lead Time  %s ' % (time)) 
        lead_fin=[]
        lead_new=lead_int
        sort_rep=dirmodel  
        cl_config_use = cl_config
        if  time == 'forecast' : 
            lead_new=[time[0]+time[4]+time[6:8]+element for element in lead_new ]
            lead_fin=lead_new
        elif time == 'persistence' :
            if filter(lambda x: 'best_weekly' in x, lead_time)  :
                lead_fin=['pers']
            else :
                lead_tmp=['nwct']
                lead_new=[time[:4]+element for element in lead_new[1:] ]
                lead_tmp.extend(lead_new)
                lead_fin=lead_tmp
        elif time == 'best_estimate' :
                cl_config_use = re.sub('Q','',cl_config)
                lead_fin=['hdct']
                log.info('Lead fin %s ' % (lead_fin)) 
        elif time == 'best_weekly' :
             lead_fin=['hdct','nwct']
        else : 
            log.error('Lead time %s not expected ' %(time))
        config_d=re.sub("V","QV",cl_config) 
        ## Find and Load the good file
        for directory in lead_fin :
            modele=cl_config_use
            log.info('directory %s' %(directory))
            log.info('model %s' %(modele))
            if directory == 'hdct' :
                dirmodel_new=dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
            else :
                dirmodel_new=dirmodel+"DAILY/"+modele[:5]+"/"+modele.lower()+"/"
            print dirmodel_new+directory+"/"+modele+"_"+daily_pref+"_"+dateval+"*_icemod*.nc"
            list_file=glob.glob(dirmodel_new+directory+"/"+modele+"_"+daily_pref+"_"+dateval+"*_icemod*.nc")
            log.info('dirmodel  %s ' % (dirmodel)) 
            log.info('directory and file  %s %s ' % (directory,list_file[0])) 
            ## Read concentration 
            ## Do the interp
            #conc_idw = np.sum(w * conc_mod.flatten()[inds_idw1], axis=1) / np.sum(w, axis=1)

sys.exit(1)
if ll_file_interp and ll_file_ok :
    ## Load position 
    log.info('Data origin %s ' %(data_origin))
    while valeurj.__ge__(date1) and valeurj.__le__(date2) :
        log.info('Interp day  %s ' % (SyDate.__str__(valeurj))) 
        dateval=SyDate.__str__(valeurj)
        valeurj=valeurj.goforward(1)
        # =============================================================================
        # PART-4 - Colocations of positions
        # =============================================================================
        log.info('==========================================')
        log.info('               Coloc Files                ') 
        log.info('==========================================')
        ll_coloc=False
        file_coloc=coloc_rep+"Kdtree_PGN_idw4pt_"+dateval+".p"
        if os.path.isfile(file_coloc) : 
            ll_coloc=True
            print "coloc existe %s " %(file_coloc)
            print "load existing tree"
            ##f = file(file_coloc, 'r')
            ##zip_var=cPickle.load(f)
            ##d,inds_idw=zip(*zip_var)
            ##d1=np.array(d)
            ##inds_idw1=np.array(inds_idw)
            ##f.close
            print "read ok"
        if not ll_coloc :
            log.info('Coordinates %s ' %(coordinates))
            lon_mod,lat_mod=Loader.factory('PGN_coords').read_pos(coordinates)
            print "coloc don't exist => coloc with KDtree"
            xs, ys, zs = lon_lat_to_cartesian(lon_mod.flatten(), lat_mod.flatten())
            print "Create CKDTREE object"
            sys.exit(1)
            tree = cKDTree(zip(xs, ys, zs))
            print "inverse distance weighting approach"
            d1, inds_idw1 = tree.query(zip(xt, yt, zt), k = 4)
            print "create tree ok"
            f = file(filename1, 'wb')
            cPickle.dump(zip(d1,inds_idw1),f,protocol=cPickle.HIGHEST_PROTOCOL)
            print "dump ok"
            f.close
            ll_tree=True
        ## Compute the weigths
        #w = 1.0 / d1**2 
        ##
        log.info('=======================================================')
        log.info('               Create output file                      ')
        log.info('=======================================================')
        ## Create matrix
        pers_tab=np.ndarray(shape=(nbtimes,1,10,1),dtype=float, order='F')
        fcst_tab=np.ndarray(shape=(nbtimes,1,10,1),dtype=float, order='F')
        pers_tab[:,:,:,:]=9999.
        fcst_tab[:,:,:,:]=9999.
        # =============================================================================
        # PART-5 - Compute interpolation
        # =============================================================================
        log.info('=======================================================')
        log.info('               Compute interpolation                   ')
        log.info('=======================================================')
        for time in lead_time : 
            log.info('Lead Time  %s ' % (time)) 
            lead_fin=[]
            lead_new=lead_int
            sort_rep=dirmodel  
            cl_config_use = cl_config
            if  time == 'forecast' : 
                #cl_config_use = cl_config[0:4]+'Q'+cl_config[4:]
                lead_new=[time[0]+time[4]+time[6:8]+element for element in lead_new ]
                lead_fin=lead_new
            elif time == 'persistence' :
                if filter(lambda x: 'best_weekly' in x, lead_time)  :
                    lead_fin=['pers']
                else :
                    lead_tmp=['nwct']
                    lead_new=[time[:4]+element for element in lead_new[1:] ]
                    lead_tmp.extend(lead_new)
                    lead_fin=lead_tmp
            elif time == 'best_estimate' :
                cl_config_use = re.sub('Q','',cl_config)
                lead_fin=['hdct']
                log.info('Lead fin %s ' % (lead_fin)) 
            elif time == 'best_weekly' :
                lead_fin=['hdct','nwct']
            elif time == 'CLIM_WOA05' :
                dirclim4=param_dict.get('climato','DIRCLIM4')
                lead_fin=['clim4']
                sort_rep=dirclim4
            elif time == 'CLIM_WOA09' :
                dirclim1=param_dict.get('climato','DIRCLIM1')           
                lead_fin=['clim1']
                sort_rep=dirclim1
            elif time == 'CLIM_ARV11' :
                dirclim2=param_dict.get('climato','DIRCLIM2')           
                lead_fin=['clim2']
                sort_rep=dirclim2  
            elif time == 'CLIM_WOA13' :
                dirclim3=param_dict.get('climato','DIRLEV')           
                lead_fin=['clim']
                sort_rep=dirclim3  
            elif time == 'CLIM_MED' :
                dirclim=param_dict.get('climato','DIRCLIM')
                lead_fin=['clim']
                sort_rep=dirclim
            else : 
                log.error('Lead time %s not expected ' %(time))
            config_d=re.sub("V","QV",cl_config) 
            ## Find and Load the good file
            for directory in lead_fin :
                modele=cl_config_use
                log.info('directory %s' %(directory))
                log.info('model %s' %(modele))
                if directory == 'hdct' :
                    dirmodel_new=dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
                else :
                    dirmodel_new=dirmodel+"DAILY/"+modele[:5]+"/"+modele.lower()+"/"
                print dirmodel_new+directory+"/"+modele+"_"+daily_pref+"_"+dateval+"*_icemod*.nc"
                list_file=glob.glob(dirmodel_new+directory+"/"+modele+"_"+daily_pref+"_"+dateval+"*_icemod*.nc")
                log.info('dirmodel  %s ' % (dirmodel)) 
                log.info('directory and file  %s %s ' % (directory,list_file[0])) 
                ## Do the interp
                #conc_idw = np.sum(w * conc_mod.flatten()[inds_idw1], axis=1) / np.sum(w, axis=1)
                
sys.exit(1)

            #Design().factory(data_origin).run(filename,dateval,contact,cl_config_d,model_type.lower(),inst,version,desc)
## Zipped files and move in output directory 
for filename in glob.glob(dirwork+"*.nc") :
    f_in=open(filename,'rb')
    f_out=gzip.open(filename+'.gz','wb')
    f_out.writelines(f_in)
    f_out.close()
    f_in.close()
    log.info('File ok %s' %(filename))
    shutil.move(filename+'.gz',diroutput)
    os.remove(filename)
sys.exit(1)
# Lancement du run d'après
DAYMAX=param_dict.get('GLOBAL','DAY_MAX')
## Clear stuck objects
sys.exc_clear()
sys.exc_traceback = sys.last_traceback = None
##
if DAYMAX : 
    dayvalmax=SyDate(DAYMAX)
    schedule=param_dict.get('GLOBAL','SCHEDULE')
    if schedule == "MONTHLY" : 
        date_next=date1.goforward(31)
        date_next=date1.goforward(31)
    elif schedule == "WEEKLY" :
        date_next=SyDate(daterun).goforward(7)
    elif schedule == "YEARLY" :
        date_next=date1.goforward(365)
    elif schedule == "DAILY" :
        date_next=SyDate(daterun).goforward(1)
    else : 
        log.error("Schedule not found %s" %(schedule))
    if  date_next < dayvalmax :
        if schedule == "MONTHLY" : 
            cl_date=SyDate.__str__(date_next)[0:6]
            cl_date2=SyDate.__str__(dayvalmax)[0:6]
            code_lancement='python '+homedir+'script/TEP_CLASS4.py --config='+cl_config+'  --date1='+cl_date+ \
                 '  --date2='+cl_date2+' --src='+cl_src+'  --data='+data_type
        elif schedule == "WEEKLY" :
            cl_daterun=SyDate.__str__(date_next)
            print 'Lancement du run %s ' %(cl_daterun)
            code_lancement='python '+homedir+'script/TEP_CLASS4.py --config='+cl_config+'  --daterun='+cl_daterun+ \
                    '  --nbdate=7 --delta=7 --src='+cl_src+'  --data='+data_type
        elif schedule == "DAILY" :
            cl_daterun=SyDate.__str__(date_next)
            print 'Lancement du run %s ' %(cl_daterun)
            code_lancement=homedir+'script/Launcher_NAVITI_cycle.ksh '+cl_config+'  '+cl_daterun+' '+str(nb_proc)
        elif schedule == "YEARLY" :
            cl_daterun=SyDate.__str__(date_next)
            print 'Lancement du run %s ' %(cl_daterun)
            code_lancement='python '+homedir+'script/TEP_CLASS4.py --config=PSY4V3R1 --date1='+cl_daterun[0:4]+' --src=CORA4 --data=profile --typemod=allege'
        else : 
            log.error("Schedule not found %s" %(schedule))
        print code_lancement
        try:
            os.system(code_lancement)
            print "Lancement date run %s ok " % (cl_date)
        except:
            print 'Probleme execution'
            sys.exit(1)

    else :
        print 'Dépassement de JMAX : %s ' % (SyDate.__str__(date_next))
        sys.exit(1)
