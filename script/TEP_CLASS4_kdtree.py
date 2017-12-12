# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
# History  : Juillet 2014  : Creation C.REGNIER 
#            Novembre 2014 :  Ajout différentes échéances pour l'interpolation + clims + gestion enchaînement des runs
#            Decembre 2014 :  MAJ pour le cas particulier du zoom
#            November 2016 :  New version with KDtree method for coloc and interp
#            November/Dec 2017 :  Add modules in a generic lib for CLASS4 portability / Generic KDtree for SLA,SST,SSS
## Description : 
## New CLASS4 launcher to compute CLASS4 with CLASS4 coming from GODAE, ARMOR, CORIOLIS
#
from __future__ import generators
import os,sys,string,shutil,glob,re
## Import specific python_modules
sys.path.append('../python_modules/')
import logging
import resource
## Import local modules
from Selector import Selector
from Writer import Writer
from Extractor import Extractor
from NmlCreator import NmlCreator
from Sorter import Sorter
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
import gzip
from Utils import *
#for serialization 
import cPickle
#for interpolation
from scipy.spatial import cKDTree

from NetcdReader import *
from netCDF4 import Dataset

from Loader import *
from sytoolkit.sydate import SyDate

## Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

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
log.info("Datatype %s " %(data_type))
# ==================================
#   Load db configuration file
# ==================================
CONF_PATH=os.getcwd()
#CONF_PATH="/home/cregnier/SVN/mo/TEP_CLASS4_V3/script"
filename = [CONF_PATH+'/'+confname]
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
type_archi=param_dict.get('GLOBAL','TYPE_ARCHI')
varname=param_dict.get('GLOBAL','variable')
nb_points=int(param_dict.get('GLOBAL','nb_points_interp'))
schedule=param_dict.get('GLOBAL','SCHEDULE')
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
    log.info('do decomp')
    list_files=Extractor().factory(prefix_data).run(date1,date2,dirdata,dirwork,data_type,template,prefix_data)
else :
    log.info('========================================================')
    log.info('              DATE Selection and extraction  %s         ' %(prefix_data)) 
    log.info('========================================================')
    list_files=Extractor().factory(prefix_data).run_list(date1,date2,dirdata,dirwork)

if not list_files : 
    log.error('Missing files')
    sys.exit(1)
else :
    log.info('List Files  %s ' % (list_files))

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
if data_type.lower() == "sst" or data_type.lower() == "ssthf" : 
    gridtype="gridT"
elif data_type.lower() == "sss" :
    gridtype="gridS"
elif data_type.lower() == "sla" :
    gridtype="grid2D"
elif data_type.lower() == "chloro" :
    gridtype="gridCHL"
elif data_type.lower() == "aice" :
    gridtype="icemod"

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
            selector=Selector(data_format,data_type).factory(data_origin)
            if data_origin == "Microwat":
                print "OK"
                lon,lat,juld=Loader.factory(data_format).read_pos(fichier)
            else :
                lon,lat,obs_value=Loader.factory(data_format).read_pos_and_value(fichier)
            nb_obs=int(np.shape(lat)[0])
            new_position=np.ndarray(shape=(nb_obs,2),dtype=float, order='F')
            new_position[:,0]=lon
            new_position[:,1]=lat
            if lon.ndim < 2 :
                #X, Y = np.meshgrid(lon,lat)
                X, Y = lon,lat
                #ny,nx=np.shape(X)
                #print(nx,ny)
                ## Convert to cartesian
                xt, yt, zt = lon_lat_to_cartesian(X.flatten(),Y.flatten())
            else :
                xt, yt, zt = lon_lat_to_cartesian(lon, lat)
            log.info("Data origin %s" %(data_origin))
        # =============================================================================
        # PART-4 - Colocations of positions
        # =============================================================================
        log.info('==========================================')
        log.info('               Coloc Files                ') 
        log.info('==========================================')
        ll_coloc=False
        file_coloc_tmp=os.path.basename(fichier)
        file_out=file_coloc_tmp
        file_coloc_tmp=re.sub('.nc','_Kdtree_PGN_idw'+str(nb_points)+'pt.p',file_coloc_tmp)
        file_coloc=coloc_rep+file_coloc_tmp
        log.info('File coloc %s ' %(file_coloc))
        if os.path.isfile(file_coloc) : 
            ll_coloc=True
            log.info('coloc existe %s '  %(file_coloc))
            log.info('load existing tree')
            f = file(str(file_coloc), 'r')
            zip_var=cPickle.load(f)
            d,inds_idw=zip(*zip_var)
            d1=np.array(d)
            inds_idw1=np.array(inds_idw)
            f.close
            log.info('read tree ok')
        if not ll_coloc :
            log.info('Coordinates %s ' %(coordinates))
            lon_mod,lat_mod=Loader.factory('PGN_coords').read_pos(coordinates)
            log.info('coloc don t exist => coloc with KDtree')
            xs, ys, zs = lon_lat_to_cartesian(lon_mod.flatten(), lat_mod.flatten())
            log.info('Create CKDTREE object')
            tree = cKDTree(zip(xs, ys, zs))
            log.info('query approach')
            d1, inds_idw1 = tree.query(zip(xt, yt, zt), k =  nb_points)
            log.info('File coloc %s ' %(file_coloc))
            f = file(str(file_coloc), 'wb')
            cPickle.dump(zip(d1,inds_idw1),f,protocol=cPickle.HIGHEST_PROTOCOL)
            log.info('dump ok')
            f.close
            ll_tree=True
        if nb_points > 1 :
            ## Compute the weigths
            w = 1.0 / d1**2 
        ## Create matrix
        log.info('Number obs to coloc %i ' % (nb_obs)) 
        if data_origin == "Microwat":
            hdct_tab=np.ndarray(shape=(nb_obs,),dtype=float, order='F')
            hdct_tab[:]=9999.
        else :
            hdct_tab=np.ndarray(shape=(nb_obs,1,1),dtype=float, order='F')
            pers_tab=np.ndarray(shape=(nb_obs,1,10,1),dtype=float, order='F')
            fcst_tab=np.ndarray(shape=(nb_obs,1,10,1),dtype=float, order='F')
            pers_tab[:,:,:,:]=9999.
            fcst_tab[:,:,:,:]=9999.
        ll_miss=False
        log.info("Colloc OK")
        if write_geojson  :
            # Store input position and coloc position to plot the results in a GIS like qGis 
            # Input
            ## Store only ext files for extract area
            type_f=os.path.basename(fichier).split('_')[2]
            length=new_position.size
            file_json=dirtmp+'Positions_'+data_format+'_'+data_type+'_D'+dateval+'_'+SyDate.__str__(date2)+'.geojson'
            log.info('File out geojson %s' %(file_json))
            if length > 1 :
                log.info("Write geojson positions %s " %(data_origin))
                Writer().write_geojson(file_json,new_position)
                #write_geojsonselector.store_pos(new_position,data_origin,file_db)
            else :
                print "No position to store %s " %(type_f)
           # Writer().write_geojson_fromdb(data_type,file_out,file_db)
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
                if cl_config[0:6] == 'BIOMER' : 
                    lead_new=[time[0]+time[4]+time[6:8]]
                else :
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
            ind=0
            for directory in lead_fin :
                modele=cl_config_use
                log.info('directory %s' %(directory))
                log.info('model %s' %(modele))
                if directory == 'hdct' :
                    dirmodel_new=dirmodel+"HEBDO/"+modele[:4]+"/"+modele.lower()+"/"
                    dirmodel_new=dirmodel
                else :
                    dirmodel_new=dirmodel+"DAILY/"+modele[:5]+"/"+modele.lower()+"/"
               # list_file=glob.glob(dirmodel_new+directory+"/"+modele+"_"+daily_pref+"_"+dateval+"*_icemod*.nc")
                ## Compute date
                if daily_pref == '7dAV' : 
                    jdatemin=SyDate(str(dateval))
                    daytogo=2-jdatemin.weekday()
                    if daytogo > 0 : 
                        first_date=jdatemin.goforward(daytogo)
                    else :
                        nbdate=14
                        daytogo2=nbdate+daytogo
                        first_date=jdatemin.goforward(daytogo2)
                    daterun=first_date
                    date1=daterun.gobackward(14)
                    date2=daterun.gobackward(7)
                    template=modele+'_'+daily_pref+'_'+str(date1)+'_'+str(date2)+'_'+gridtype+'_R'+str(daterun)
                    list_file=glob.glob(dirmodel_new+template+"*.nc")
                else :
                    list_file=glob.glob(dirmodel_new+"/"+modele+"_"+daily_pref+"_"+dateval+"*_*"+gridtype+"*.nc")
                if not list_file :
                    log.error("File missing for %s" %(directory))
                    ll_miss=True
                    sys.exit(1)
                log.info('dirmodel  %s ' % (dirmodel)) 
                log.info('directory and file  %s %s ' % (directory,list_file[0])) 
                ## Netcdf value
                fichier=str(list_file[0])
                fc = Dataset(fichier)
                if data_type.lower() == 'aice' or data_type.lower() == 'sla'  or data_type.lower() == 'chloro' :
                    value_mod = fc.variables[str(varname)][0,:,:]
                    log.info("load dataset ok")
                elif data_type == 'sss' or data_type == 'sst' : 
                    log.info("sss or sst variable")
                    value_mod = fc.variables[str(varname)][0,0,:,:]
                elif data_type.lower() == 'ssthf' : 
                    log.info("sst_hf and selection")
                    value_mod = fc.variables[str(varname)][:,:,:]
                    time_mod = fc.variables['time_counter'][:]
                else :
                    log.info("read varname %s" %(varname))
                    value_mod = fc.variables[varname][:,:,:,:]
                if nb_points > 1 :
                    ## Do the interp
                    interp = np.sum(w * value_mod.flatten()[inds_idw1], axis=1) / np.sum(w, axis=1)
                else :
                    ## Nearest neighbour interpolation
                    interp = value_mod.flatten()[inds_idw1].reshape(lon.shape)
                if data_origin == "GLOBCOLOUR" :
                    ## Fill with gaps
                    interp2D=interp.reshape(X.shape)
                    interp2D=np.where(np.array(obs_value)==-999,-999,np.array(interp2D))
               # ind_values=np.where(obs_value == -999)
                log.info('Interp ok ')
                if  time == 'forecast' : 
                    fcst_tab[:,0,ind,0]=interp[:]
                elif time == 'persistence' :
                    pers_tab[:,0,ind,0]=interp[:]
                elif time == 'best_estimate' :
                    if data_origin == "Microwat":
                        hdct_tab[:]=interp[:]
                    else :
                        hdct_tab[:,0,0]=interp[:]
                ind+=1
        log.info("Interp ok")
        ## Write in the file
        if not ll_miss : 
            log.info("Write file")
            filename_new=dirwork+file_out
            if data_origin == "Microwat" :
                # Add missing value
                print filename_new
                hdct_tab=np.where(np.array(hdct_tab)>9.e36,np.nan,np.array(hdct_tab))
                Writer().write_best(filename_new,hdct_tab,dateval,modele)
            elif data_origin == "GLOBCOLOUR" :
                Writer().write_best_fcst(filename_new,hdct_tab,fcst_tab,dateval,modele)
            else : 
                Writer().write_GODAE_files(filename_new,hdct_tab,fcst_tab,pers_tab,dateval,modele)
            ## Zipped files and move in output directory 
            file_out2=os.path.basename(file_out)
            file_out2=re.sub('.nc','_'+str(cl_config)+'.nc',file_out2)
            for fileout in glob.glob(dirwork+"*"+dateval+"*.nc") :
                shutil.move(fileout,diroutput+file_out2)
            log.info('----------------------------')
            log.info('Creation file ok %s' %(diroutput+file_out2))
            log.info('----------------------------')
            ##    log.info('ZIP and move file %s' %(filename))
            ##    f_in=open(filename,'rb')
            ##    f_out=gzip.open(filename+'.gz','wb')
            ##    f_out.writelines(f_in)
            ##    f_out.close()
            ##    f_in.close()
            ##    log.info('File ok %s' %(filename))
            ##    if os.path.exists(diroutput+os.path.basename(filename)+'.gz'):
            ##        os.remove(diroutput+os.path.basename(filename)+'.gz')
            ##    os.remove(filename)
        else : 
            log.info('File missing')
