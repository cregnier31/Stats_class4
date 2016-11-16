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
#sys.path.append("/home/modules/versions/64/fc18/ipython/ipython-1.1/lib/python2.7/site-packages")
#sys.path.append("/home/modules/versions/64/fc18/netcdf4-python/netcdf4-python-1.0.7/lib64/python2.7/site-packages/")
sys.path.append("/home/ext/mr/smer/regnierc/SAVE/python/module/")
sys.path.append("/home/ext/mr/smer/regnierc/SAVE/python/module/lib/python2.6/site-packages/")
sys.path.append("/home/ext/mr/smer/regnierc/SAVE/python/module/lib/python2.6/site-packages/nco-0.0.2-py2.6.egg/")
sys.path.append("/home/ext/mr/smer/regnierc/SAVE/python/module/geojson-1.0.7/")
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
import time
from multiprocessing import Pool 
from math import *
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
level=2
log=Logger("TEP_CLASS4").run(level)


def run_coloc(args):
    file_pos = args[0]
    # ==================================
    #   Load db configuration file
    # ==================================
    CONF_PATH=os.getcwd()
    filename = [CONF_PATH+'/'+confname]
    param_dict=Loader.factory('NML').load(filename,level)
    model_type=param_dict.get('GLOBAL','MODELTYPE')
    dirwork=param_dict.get('output_dir', 'DIROUTPUT')
    nml_dir=param_dict.get('GLOBAL','NAMELIST_DIR')
    direxec=param_dict.get('GLOBAL','EXEDIR')
    data_origin=param_dict.get('input_dir','DATA_ORIGIN')
    cl_config=param_dict.get('GLOBAL','CONFIGURATION')
    coloc_rep=param_dict.get('output_dir','DIRCOLOC')
    dir_log=param_dict.get('GLOBAL','DIRLOG')
    coordinates=param_dict.get('static','fic_coordinates')
    maskvar=param_dict.get('static','maskname')

    # =============================================================================
    # PART-4 - Colocations of positions
    # =============================================================================
    code_lancement=direxec+'CLASS4_create_colocfile_ASCII_'+cl_config+'.exe'+' '+'-g'+' '+coordinates+' '+'-r'+' '+file_pos+' ' \
     			   +'-c'+' '+cl_config+' '+'-m'+' '+maskvar
    print code_lancement
    # subprocess.call(code_lancement)
    try:
        #subprocess.check_output(code_lancement,stderr=subprocess.STDOUT,shell=True)
        print code_lancement
        #subprocess.check_call(code_lancement)
        os.system(code_lancement)
    except IOError as e:
        log.error("Probleme execution")
        log.error("Fichier %s" %file_pos )
        log.error("I/O error({0}): {1}".format(e.errno, e.strerror))

tic = time.time()
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
log.info("Type des fichiers d'entree %s " %(cl_typemod))
log.info("Nombre de proc %i" %(nb_proc))
# ==================================
#   Load db configuration file
# ==================================
CONF_PATH=os.getcwd()
CONF_PATH="/home/ext/mr/smer/regnierc/SAVE/DEV/TEP_CLASS4_V4/script"
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
dirstatic=param_dict.get('static','dir_static')

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
    list_files=Extractor().factory(prefix_data).run(date1,date2,dirdata,dirwork,data_type,template)
elif do_decomp : 
    print 'do decomp'
    print prefix_data
    print date1,date2,dirdata,dirwork,data_type,template,prefix_data
    list_files=Extractor().factory(prefix_data).run(date1,date2,dirdata,dirwork,data_type,template)
else :
    log.info('========================================================')
    log.info('              DATE Selection and extraction  %s         ' %(prefix_data)) 
    log.info('========================================================')
    print prefix_data
    list_files=Extractor().factory(prefix_data).run_list(date1,date2,dirwork)


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
        if data_type ==  "AMSR" :
            position=Loader.factory(data_format).read_pos_amsr(fichier)
        else :
            position=Loader.factory(data_format).read_pos(fichier)
        new_position=position
        selector=Selector(data_format,data_type).factory(data_origin)
        ll_file_ok=True
        ll_file_interp=True
    ## Case  : File in the area selection
    if ll_file_interp : 
        ll_coloc=False
        # Write ASCII pos for Coloc
        file_pos_tmp=os.path.basename(fichier)
        file_pos_tmp=re.sub('.nc','.pos',file_pos_tmp)
        file_pos=coloc_rep+file_pos_tmp
        print file_pos
        Writer().write_ASCII(file_pos,new_position)
        list_filepos.append(file_pos)
        #  splitLen = 1000000       # 500000 lines per file
        file_in=file_pos
        outputBase = file_pos.split('.pos')[0]
        fileout=outputBase+'.dat'
        if os.path.isfile(fileout) : 
            ll_coloc=True
            print "coloc existe %s " %(fileout)
        if not ll_coloc : 
            print "coloc don't exist"
            outputBase=re.sub("coloc","coloc/split",outputBase) 
            outputBase_orig = file_pos.split('.pos')[0]
            input=open(file_in,'r').read().split('\n')
            cpt=1
            nb_pts=len(input)
            nb_process=nb_proc
            print nb_pts,nb_process
            splitLen=int(ceil(nb_pts/nb_process))+1
            print splitLen
            for lines in range(0,len(input),splitLen):
                # First, get the list slice
                outputData = input[lines:lines+splitLen]
                # Now open the output file, join the new slice with newlines
                # and write it out. Then close the file.
                output = open(outputBase +'_split'+ str(cpt) + '.pos', 'w')
                print ('Output %s ok'%(output))
                output.write('\n'.join(outputData))
                output.close()
                print ('Split %s ok'%(cpt))
                cpt += 1
            #===========================================================================================
            # Colocation in multiprocessing
            #===========================================================================================
            log.info("Multiprocessing ")
            ### 2eme solution
            log.info("List file %s "  %(outputBase))
            list_files=glob.glob(outputBase+"*split*.pos")
            log.info(list_files)
            mp_pool = Pool(nb_process)
            mp_pool.map(run_coloc, [ [x] for x in list_files ])
            ## TODO
            ## Recombinaisons of .dat
            log.info("Coloc ok start recombination ")
            toc = time.time()
            print '%s elapsed time' %(toc-tic)
            ind=1
            ind_tot=1
            fileout=outputBase_orig+'.dat'
            log.info("file out : %s " %(fileout))
            with open(fileout, 'w') as outFile:
                for i in range(1,nb_process+1):
                    filename=outputBase +'_split'+ str(ind) + '.dat'
                    input=open(filename,'r').read()
                    outFile.write(input)     
                    ind=ind+1
            log.info("Recombination OK")
            # Cleanup
            for filename in glob.glob(outputBase+"*split*"): 
                os.remove(filename)

        if write_geojson  :
               # Store input position and coloc position to plot the results in a GIS like qGis 
           # Input
           ## Store only ext files for extract area
           type_f=os.path.basename(fichier).split('_')[2]
           length=new_position.size
           if length > 1 :
              log.info("Store geojson positions %s " %(type_f))
              selector.store_pos(new_position,type_f,file_db)
           else :
              print "No position to store %s " %(type_f)
           # Coloc
           file_coloc=os.path.basename(fichier).split('.')[0]+'.dat'
           #coloc_pos=Loader.factory('DAT').read_pos(dirwork+'coloc/'+file_coloc)
           coloc_pos=Loader.factory('DAT').read_pos(coloc_rep+file_coloc)
           length=coloc_pos.size
           if length > 1 :
             log.info("Store geojson positions db2 %i " %(length))
             selector.store_pos_single(coloc_pos,'coloc',file_db2)
 
if ll_file_ok :
    ## Create Geojson file for coloc verification with Qgis
    if write_geojson : 
        liste_type=['GLO','XB','CT','DC','BA','GL','ML','PF','TE','DB','FB','MO','TS']
        for type_var in liste_type : 
            ## Write files with positions of dataset
            file_out=dirtmp+'Positions_'+type_var+'_'+data_format+'_'+data_type+'_D'+SyDate.__str__(date1)+'_'+SyDate.__str__(date2)+'.geojson'
            Writer().write_geojson_fromdb(type_var,file_out,file_db)
        file_out2=dirtmp+'Positions_coloc_'+data_type+'_'+data_format+'_'+data_type+'_D'+SyDate.__str__(date1)+'_'+SyDate.__str__(date2)+'.geojson'
        Writer().write_geojson_fromdb('coloc',file_out2,file_db2)

    # =============================================================================
    # PART-5 - Compute interpolation
    # =============================================================================
    log.info('=======================================================')
    log.info('               Compute interpolation                   ')
    log.info('=======================================================')
    ## Create object interpolator depending on data type
    ll_mssh=None
    if data_type  == "SLA" : 
        cl_msshFile =param_dict.get('static','cl_msshFile'   )      #  the mean ssh from SSH model 
        rl_mssh_shift=float(param_dict.get('static','rp_mssh_shift' ))
        comp_mssh=int(param_dict.get('GLOBAL','comp_mssh'))
        ll_mssh='.true.'
        if comp_mssh == 1  :
            ll_compute='.true.'
        else :
            ll_compute='.false.'
    else : 
        cl_msshFile =''
        rl_mssh_shift=0.0
        ll_mssh='.false.'
        ll_compute='.false.'
    contact=param_dict.get('GLOBAL','CONTACT')
    inst=param_dict.get('GLOBAL','INSTITUTION')
    version=param_dict.get('GLOBAL','VERSION')
    desc=param_dict.get('GLOBAL','DESCRIPTION')
    valeurj=date1
    log.info('Data origin %s ' %(data_origin))
    while valeurj.__ge__(date1) and valeurj.__le__(date2) :
        log.info('Interp day  %s ' % (SyDate.__str__(valeurj))) 
        dateval=SyDate.__str__(valeurj)
        nml=os.path.join(nml_dir,'interpolate_3D_%s_%s_%s.nml' %(data_type.upper(),cl_config,dateval))
        valeurj=valeurj.goforward(1)
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
            elif time == 'best_estimate' or time == 'best_estimate_RTR' :
                cl_config_use = re.sub('Q','',cl_config)
                lead_fin=['hdct']
                #log.info('Lead fin %s ' % (lead_fin)) 
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
                dirclim3=param_dict.get('climato','DIRCLIM3')           
                lead_fin=['clim3']
                sort_rep=dirclim3  
            elif time == 'CLIM_MED' :
                dirclim=param_dict.get('climato','DIRCLIM')
                lead_fin=['clim']
                sort_rep=dirclim
            else : 
                log.error('Lead time %s not expected ' %(time))
            if data_type ==  "AMSR" :
                exe    = 'CLASS4_spatial_interpolation_'+data_origin+'_AMSR.exe'
                print "AMSR"
            else :
                exe    = 'CLASS4_spatial_interpolation_'+data_origin+'.exe'    
            exe = os.path.join(direxec,exe)
            if data_origin == 'CORIOLIS' :
                nml=os.path.join(nml_dir,'interpolate_3D_%s_%s_%s_%s.nml' %(data_type.upper(),cl_config,time,dateval))
                NmlCreator(cl_msshFile,ll_mssh,ll_compute,rl_mssh_shift).factory(data_origin).run(nml,cl_config_use,daily_pref,data_type , \
    	                            						       time,sort_rep,coloc_rep,dirwork,time,dateval,gridtemp,gridsal,cl_schedule,type_run)  	
                #log.info('NmlCreator OK')
                if not os.path.exists(exe) :
                    print 'Did not find executable %s' %exe
                    sys.exit(1)
                codexe = '%s -r %s -c %s -m %s -l %s' %(exe,dateval,nml,cl_config_use,dir_log)
                args   = shlex.split(codexe)
                print(args)
                try :   subprocess.check_call(args)
                except :
                    print 'executable %s failed' %exe
                    sys.exit(1)
    	   
    	    ## Case GODAE
            if data_origin == 'GODAE' : 
                ##    Create namelist 
                log.info('Create namelist') 
                #for filename in glob.glob(dirwork+"*"+dateval+"*"+data_type+"*.nc") :
                for filename in glob.glob(dirwork+"*"+dateval+"*.nc") :
                    print filename
                    print ll_compute
                    NmlCreator(cl_msshFile,ll_mssh,ll_compute,rl_mssh_shift).factory(data_origin).run(nml,cl_config_use,daily_pref,data_type , \
                               time,dirmodel,coloc_rep,filename,lead_fin,dateval,gridtemp,gridsal)  	
    	           ## Launch Interpolation  
                if not os.path.exists(exe) : 
                    print 'Did not find executable %s' %exe
                    sys.exit(1)
                codexe = '%s -r %s -c %s -m %s' %(exe,dateval,nml,cl_config_use) 
                args   = shlex.split(codexe)
                try :   subprocess.check_call(args)
                except :
                    print 'executable %s failed' %exe
                    sys.exit(1)
    	        ## Design File
                config_d=re.sub("V","QV",cl_config) 
                Design().factory(data_origin).run(filename,dateval,contact,config_d,model_type.lower(),inst,version,desc)
        ## Zipped files and move in output directory 
        for filename in glob.glob(dirwork+"*"+dateval+"*.nc") :
            ## Copy in other repertory
            #shutil.copy(filename,diroutput+os.sep+'dezip')
            #f_in=open(filename,'rb')
            #f_out=gzip.open(filename+'.gz','wb')
            #f_out.writelines(f_in)
            #f_out.close()
            #f_in.close()
            log.info('File ok %s' %(filename))
            shutil.move(filename,diroutput)
            #os.remove(filename)
### Lancement du run d'après
##DAYMAX=param_dict.get('GLOBAL','DAY_MAX')
#### Clear stuck objects
##sys.exc_clear()
##sys.exc_traceback = sys.last_traceback = None
####
##if DAYMAX : 
##   dayvalmax=SyDate(DAYMAX)
##   schedule=param_dict.get('GLOBAL','SCHEDULE')
##   if schedule == "MONTHLY" : 
##      date_next=date1.goforward(31)
##   elif schedule == "WEEKLY" :
##     date_next=SyDate(daterun).goforward(7)
##   elif schedule == "DAILY" :
##     date_next=SyDate(daterun).goforward(1)
##   else : 
##     log.error("Schedule not found %s" %(schedule))
##   if  date_next < dayvalmax :
##      if schedule == "MONTHLY" : 
##          cl_date=SyDate.__str__(date_next)[0:6]
##          cl_date2=SyDate.__str__(dayvalmax)[0:6]
##          code_lancement='python '+homedir+'script/TEP_CLASS4.py --config='+cl_config+'  --date1='+cl_date+ \
##               '  --date2='+cl_date2+' --src='+cl_src+'  --data='+data_type
##      elif schedule == "WEEKLY" :
##          cl_daterun=SyDate.__str__(date_next)
##          print 'Lancement du run %s ' %(cl_daterun)
##          code_lancement='python '+homedir+'script/TEP_CLASS4.py --config='+cl_config+'  --daterun='+cl_daterun+ \
##               '  --nbdate=7 --delta=7 --src='+cl_src+'  --data='+data_type
##      elif schedule == "DAILY" :
##          cl_daterun=SyDate.__str__(date_next)
##          print 'Lancement du run %s ' %(cl_daterun)
##          code_lancement=homedir+'script/Launcher_NAVITI_cycle.ksh '+cl_config+'  '+cl_daterun+' '+str(nb_proc)
##      else : 
##          log.error("Schedule not found %s" %(schedule))
##      print code_lancement
##      try:
##           os.system(code_lancement)
##           print "Lancement date run %s ok " % (cl_date)
##      except:
##         print 'Probleme execution'
##         sys.exit(1)
##      sys.exit(1)
## 
##   else :
##     print 'Dépassement de JMAX : %s ' % (SyDate.__str__(date_next))
##     sys.exit(1)
