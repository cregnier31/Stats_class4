#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: set ts=4 sw=4 expandtab:
# Creation C.REGNIER Juin/Juillet 2014
## New CLASS4 launcher to compute CLASS4 with CLASS4 coming from GODAE, ARMOR, CORIOLIS
## Add multiprocessing tasks with the help of Matthew keyboard
#
from __future__ import generators
import os,sys,string,shutil,glob,re
import logging
import resource
from QCcontrol import QCcontrol
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
from  Logger import Logger
from Sorter import Sorter
from multiprocessing import Pool 
## Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


sys.path.append("/home/cregnier/DEV/Python/NEW_CL4/")
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
    fichier = args[0]
    date1 = args[1]
    date2 = args[2]
    confname = args[3]
    data_type = args[4]
    daterun = args[5]
    # ==================================
    #   Load db configuration file
    # ==================================
    CONF_PATH=os.getcwd()
    filename = [CONF_PATH+'/'+confname]
    param_dict=Loader.factory('NML').load(filename,level)
    zoom=int(param_dict.get('GLOBAL','zoom'))
    write_geojson=int(param_dict.get('GLOBAL','write_geojson'))
    qc_level=int(param_dict.get('GLOBAL','qc_level'))
    do_qc=int(param_dict.get('GLOBAL','do_qc'))
    do_sort=int(param_dict.get('GLOBAL','do_sort'))
    model_type=param_dict.get('GLOBAL','MODELTYPE')
    dirmodel=param_dict.get('input_dir', 'DATA_IN')
    data_format=param_dict.get('input_dir', 'DATA_FMT')
    dirwork=param_dict.get('output_dir', 'DIROUTPUT')
    dirtmp=dirwork+'ext-'
    nml_dir=param_dict.get('GLOBAL','NAMELIST_DIR')
    daily_pref=param_dict.get('GLOBAL','DAILY_PREF')
    direxec=param_dict.get('GLOBAL','EXEDIR')
    data_origin=param_dict.get('input_dir','DATA_ORIGIN')
    cl_config=param_dict.get('GLOBAL','CONFIGURATION')
    template=cl_config+'_'+model_type
    lead_time=param_dict.get('input_dir','LEAD_TIME').split()
    lead_int=param_dict.get('input_dir','LEAD_INT').split()
    coloc_rep=param_dict.get('output_dir','DIRCOLOC')
    dir_log=param_dict.get('GLOBAL','DIRLOG')

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
    # PART 3  : DO SORT if not available
    # =============================================================================
    if do_sort : 
        log.info('              Sort Values for interp               ') 
        sort_rep=param_dict.get('input_dir','DATA_SORT')
        schedule=param_dict.get('GLOBAL','SCHEDULE')
        gridtemp=param_dict.get('GLOBAL','gridtemp')
        gridsal=param_dict.get('GLOBAL','gridsal')
        file_template=cl_config+'_'+daily_pref+'_'
        if schedule == "WEEKLY" :
            Sorter().run_weekly(lead_time,lead_int,date1,date2,daterun,file_template,gridtemp,gridsal,dirmodel,sort_rep)
        elif schedule == "DAILY" :
            Sorter().run_daily(lead_time,lead_int,date1,date2,file_template,dirmodel,sort_rep)
        else :
            log.error("Schedule not valid")
            sys.exit(1)



    # =============================================================================
    #  PART-4 - Area Selection and QC selection
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
    ll_doc_interp=None


    log.info('Fichier  %s ' % (fichier)) 
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
            ll_doc_interp=True
        else :
            os.remove(fichier)
            log.info('No position find in %s for the zoom ' % (fichier))
            ll_doc_interp=False
            return
    else :
       # Case Global without qc
       log.info("GLOBAL MODE => SELECT ALL ") 
       position=Loader.factory(data_format).read_pos(fichier)
       new_position=position
       selector=Selector(data_format,data_type).factory(data_origin)

    # Write ASCII pos for Coloc
    file_pos_tmp=os.path.basename(fichier)
    file_pos_tmp=re.sub('.nc','.pos',file_pos_tmp)
    file_pos=coloc_rep+file_pos_tmp
    Writer().write_ASCII(file_pos,new_position)
    list_filepos.append(file_pos)
    # =============================================================================
    # PART-5 - Colocations of positions
    # =============================================================================
    log.info('==========================================')
    log.info('               Coloc Files                ') 
    log.info('==========================================')
    coordinates=param_dict.get('static','fic_coordinates')
    maskvar=param_dict.get('static','maskname')
    code_lancement=direxec+'CLASS4_create_colocfile_ASCII_'+cl_config+'.exe'+' '+'-g'+' '+coordinates+' '+'-r'+' '+file_pos+' ' \
  				   +'-c'+' '+cl_config+' '+'-m'+' '+maskvar
    log.info("File OK %s " %(fichier))   
   # subprocess.call(code_lancement)
    try:
      #subprocess.check_output(code_lancement,stderr=subprocess.STDOUT,shell=True)
        print code_lancement
  #    subprocess.check_call(code_lancement)
        os.system(code_lancement)
    except IOError as e:
        log.error("Probleme execution")
        log.error("I/O error({0}): {1}".format(e.errno, e.strerror))
        sys.exit(1)
    if write_geojson  :
        # Store input position and coloc position to plot the results in a GIS like qGis 
        # Input
        type_f=os.path.basename(fichier).split('_')[2]
        length=new_position.size
        if length > 1 :
            log.info("Store geojson positions %s " %(type_f))
            selector.store_pos(new_position,type_f,file_db)
        else :
            print "No position to store %s " %(type_f)
            # Coloc
            file_coloc=os.path.basename(fichier).split('.')[0]+'.dat'
            coloc_pos=Loader.factory('DAT').read_pos(dirwork+file_coloc)
            length=coloc_pos.size
        if length > 1 :
            selector.store_pos_single(coloc_pos,'coloc',file_db2)


def run_interp(args):
    valeurj = args[0]
    confname = args[1]
    data_type = args[2]
    # ==================================
    #   Load db configuration file
    # ==================================
    CONF_PATH=os.getcwd()
    filename = [CONF_PATH+'/'+confname]
    param_dict=Loader.factory('NML').load(filename,level)
    model_type=param_dict.get('GLOBAL','MODELTYPE')
    dirmodel=param_dict.get('input_dir', 'DATA_IN')
    dirwork=param_dict.get('output_dir', 'DIROUTPUT')
    nml_dir=param_dict.get('GLOBAL','NAMELIST_DIR')
    daily_pref=param_dict.get('GLOBAL','DAILY_PREF')
    direxec=param_dict.get('GLOBAL','EXEDIR')
    data_origin=param_dict.get('input_dir','DATA_ORIGIN')
    cl_config=param_dict.get('GLOBAL','CONFIGURATION')
    lead_time=param_dict.get('input_dir','LEAD_TIME').split()
    lead_int=param_dict.get('input_dir','LEAD_INT').split()
    coloc_rep=param_dict.get('output_dir','DIRCOLOC')
    gridtemp=param_dict.get('GLOBAL','gridtemp')
    gridsal=param_dict.get('GLOBAL','gridsal')
    dir_log=param_dict.get('GLOBAL','DIRLOG')
    do_sort=int(param_dict.get('GLOBAL','do_sort'))
    if do_sort :
        sort_rep=param_dict.get('input_dir','DATA_SORT')
    else :
        sort_rep=dirmodel
    ll_mssh=None
    if  data_type  == "SLA" : 
        cl_msshFile =eval(param_dict.get('static','cl_msshFile'   ))      #  the mean ssh from SSH model 
        rl_mssh_shift=float(param_dict.get('static','rp_mssh_shift' ))
        ll_mssh='.true.'
    else : 
        cl_msshFile =''
        rl_mssh_shift=0.0
        ll_mssh='.false.'
    contact=param_dict.get('GLOBAL','CONTACT')
    inst=param_dict.get('GLOBAL','INSTITUTION')
    version=param_dict.get('GLOBAL','VERSION')
    desc=param_dict.get('GLOBAL','DESCRIPTION')

    log.info('Interp day  %s ' % (SyDate.__str__(valeurj))) 
    dateval=SyDate.__str__(valeurj)
    nml=os.path.join(nml_dir,'interpolate_3D_%s_%s_%s.nml' %(data_type.upper(),cl_config,dateval))
    valeurj=valeurj.goforward(1)
    for time in lead_time : 
        log.info('Lead Time  %s ' % (time)) 
        lead_fin=[]
        lead_new=lead_int
        if  time == 'forecast' : 
            cl_config_use = cl_config
            #cl_config_use = cl_config[0:4]+'Q'+cl_config[4:]
            lead_new=[time[0]+time[4]+time[6:8]+element for element in lead_new ]
            lead_fin=lead_new
        elif time == 'persistence' :
            #cl_config_use = cl_config[0:4]+'Q'+cl_config[4:]
            cl_config_use = cl_config
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
        elif time == 'best_weekly' :
            cl_config_use = cl_config
            lead_fin=['hdct','nwct']
        else : 
            log.error('Lead time %s not expected ' %(time))
        exe    = 'CLASS4_spatial_interpolation_'+data_origin+'.exe'    
        exe = os.path.join(direxec,exe)
        ## Case GODAE
        if data_origin == 'GODAE' : 
            ##    Create namelist 
            for filename in glob.glob(dirwork+"*"+dateval+"*"+data_type+"*.nc") :
                log.info('Filename : %s ' % (filename)) 
                log.info('Config used : %s ' % (cl_config_use))
                NmlCreator(cl_msshFile,ll_mssh,rl_mssh_shift).factory(data_origin).run(nml,cl_config_use,daily_pref,data_type , \
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
                Design().factory(data_origin).run(filename,dateval,contact,cl_config,model_type,inst,version,desc)
         ## Case CORIOLIS
        elif data_origin == 'CORIOLIS' :
            for time in lead_fin : 
                log.info('lead time %s' % (time))     
                nml=os.path.join(nml_dir,'interpolate_3D_%s_%s_%s_%s.nml' %(data_type.upper(),cl_config,time,dateval))
                NmlCreator(cl_msshFile,ll_mssh,rl_mssh_shift).factory(data_origin).run(nml,cl_config_use,daily_pref,data_type , \
                                                   time,sort_rep,coloc_rep,dirwork,time,dateval,gridtemp,gridsal)  	
                if not os.path.exists(exe) :
                    print 'Did not find executable %s' %exe
                    sys.exit(1)
                codexe = '%s -r %s -c %s -m %s -l %s' %(exe,dateval,nml,cl_config_use,dir_log)
                args   = shlex.split(codexe)
                try :   subprocess.check_call(args)
                except :
                    print 'executable %s failed' %exe
                    sys.exit(1)
        else :
            log.error('Bad data_origin')
            sys.exit(1)


if __name__ == '__main__':
	# =============================================================================
	#  PART-1 -  Load input parameters and file
	# =============================================================================
    log.info('========================================================')
    log.info('          Load input options and parameter file         ') 
    log.info('========================================================')

	# ===========================================
	# Load options and compute date interval
	# ===========================================
    [date1,date2,confname,data_type,daterun]=Loader().factory('INPUT').load(sys.argv[1:],level)

    CONF_PATH=os.getcwd()
    filename = [CONF_PATH+'/'+confname]
    param_dict=Loader.factory('NML').load(filename,level)
    dirdata=param_dict.get('input_dir', 'INPUTDATA')
    prefix_data=param_dict.get('input_dir','PREFIX')
    dirwork=param_dict.get('output_dir', 'DIROUTPUT')
    cl_config=param_dict.get('GLOBAL','CONFIGURATION')
    model_type=param_dict.get('GLOBAL','MODELTYPE')
    template=cl_config+'_'+model_type
    write_geojson=int(param_dict.get('GLOBAL','write_geojson'))

    # =============================================================================
    #  PART-2 -  DATE Selection and extraction
    # =============================================================================
    log.info('========================================================')
    log.info('              DATE Selection and extraction             ') 
    log.info('========================================================')
    list_files=Extractor().factory(prefix_data).run(date1,date2,dirdata,dirwork,data_type,template)
    log.info('List Files  %s ' % (list_files)) 
    #===========================================================================================
    # Do Sort, are selection and colocation in multiprocessing
    #===========================================================================================
    nb_days=len(list_files)
    mp_pool = Pool(nb_days)
    print nb_days
    mp_pool.map(run_coloc, [ [x, date1,date2,confname,data_type,daterun] for x in list_files ])

	## Create Geojson file for coloc verification with Qgis
    if write_geojson  : 
        liste_type=['GLO','XB','CT','DC','BA','GL','ML','PF','TE','DB','FB','MO','TS']
        for type_var in liste_type : 
            ## Write files with positions of dataset
            file_out=dirtmp+'Positions_'+type_var+'_'+data_format+'_'+data_type+'_D'+SyDate.__str__(date1)+'_'+SyDate.__str__(date2)+'.geojson'
            Writer().write_geojson_fromdb(type_var,file_out,file_db)
        file_out2=dirtmp+'Positions_coloc_'+data_type+'_'+data_format+'_'+data_type+'_D'+SyDate.__str__(date1)+'_'+SyDate.__str__(date2)+'.geojson'
        Writer().write_geojson_fromdb('coloc',file_out2,file_db2)

	# =============================================================================
	# PART-6 - Compute interpolation
	# =============================================================================
    log.info('=======================================================')
    log.info('               Compute interpolation                   ')
    log.info('=======================================================')
    valeurj=date1
    list_date=[]
    while  valeurj.__ge__(date1) and valeurj.__le__(date2) :
        list_date.append(valeurj)
        valeurj=valeurj.goforward(1)
    nb_days=len(list_date)
    mp_pool = Pool(nb_days)
    mp_pool.map(run_interp, [ [x,confname,data_type] for x in list_date])

            
