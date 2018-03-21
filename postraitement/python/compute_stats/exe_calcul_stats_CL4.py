#!/usr/bin/env python

"""
------------------------------------------------------------------------
 Fichier batch permettant de generer les stats sur les fichiers class4 
 afin de creer des fichiers netcdf de Stats pour MyOcean2
 c. regnier Septembre 2007
 c.REGNIER  Fevrier   2007 grosse modifs
 c.REGNIER  Mai       2009 Bulletin trimestriel
 c.REGNIER  Fevrier   2010 Generalisation du code
 C.REGNIER  Septembre 2011 Ajout de supobs
 C.REGNIER  Janvier   2012 Ecriture des stats MyO2 avec les bons formats
 L.ZAWADZKI Avril     2013 conversion python, adaptation aux fichiers GODAE
 C.REGNIER  Nov       2017 Integration dans code general TEP_CLASS4 
 C.SZCZPTA  Fevrier   2018 Modif input params 
"""

import sys,os,getopt,glob
import ConfigParser
sys.path.append('../module/')
import numpy as np
import netCDF4
## modules perso
import param.Def_param_bulletin as params
import supobs
from supobs import toolkitStats
from supobs import Statslib


#~~~~~~~~~~~~~~~~~~~~~ Input parameters settings ~~~~~~~~~~~~~~~~~~~~~

letters = 's:e:c:t:' 
keywords = ['day1=', 'day2=', 'cfg=', 'datatype=' ] 
cla_opts = getopt.getopt(sys.argv[1:],letters,keywords)

cl_dateMinZone  = 'YYYYMMDD'
cl_dateMaxZone  = 'YYYYMMDD'

_DBFILE_        = './environment.cfg'

for o,p in cla_opts[0]:
  if o in ['-s','--day1']:
     cl_dateMinZone = p
  elif o in ['-e','--day2']:
     cl_dateMaxZone = p
  elif o in ['-t','--datatype']:
     cl_CL4type = p
  elif o in ['-c','--cfg']:
     _DBFILE_ = p.strip()

cla_dates = supobs.toolkitStats.char_period(cl_dateMinZone,cl_dateMaxZone)

def load_db():
        db = ConfigParser.ConfigParser()
        db.read(os.path.expanduser(_DBFILE_))
        if not db.sections():
                print "Error reading configuration file %s" %_DBFILE_
                sys.exit(1)
        return db

db = load_db()
#~
config_model = db.get('PARAMS','CONFIGMDL').upper()
config_obs   = db.get('PARAMS','CONFIGOBS').upper()
file_boxmask = db.get('NETCDF','file_boxmask' )
dircl4in     = db.get('output_dir','DIR_OUT' )
dircl4out    = db.get('output_dir','DIR_CL4OUT' )
prefix       = db.get('INPUT','PREFIX1' )
lead_time    = db.get('input_dir','LEAD_TIME').split()
grid_type    = db.get('NETCDF','grid')

try : os.mkdir(dircl4out)
except :
    if os.path.exists(dircl4out) : pass
    else : 
        print 'could not create %s' %dircl4out
        sys.exit(1)

if cl_CL4type == 'TEMP' :
    variable_name_type = params.variable_nameT_new 
    tab_prof = params.tab_prof
    lookfor = 'profile_votemper'
    tab_prof_model = params.tab_prof_model
    tab_e3t = params.tab_e3t
elif cl_CL4type == 'SST' :
    variable_name_type = params.variable_nameSST_new
    tab_prof = [0,0]
    lookfor = 'SST_votemper'
    tab_prof_model = [0,0.5]
    tab_e3t = [1]
elif cl_CL4type == 'SLA' :
    variable_name_type = params.variable_nameSLA_new
    tab_prof = [0,0]
    lookfor = 'SLA_sossheig'
    tab_prof_model = [0,0.5]
    tab_e3t = [1]
elif cl_CL4type == 'CHL' :
    variable_name_type = params.variable_nameCHL
    tab_prof = [0,0]
    lookfor = 'CHL'
    tab_prof_model = [0,0.5]
    tab_e3t = [1]
elif cl_CL4type in ['SAL','PSAL'] :
    variable_name_type = params.variable_nameS_new 
    tab_prof = params.tab_prof
    lookfor = 'profile_vosaline'
    tab_prof_model = params.tab_prof_model
    tab_e3t = params.tab_e3t
else :
    print 'unknown cl_CL4type'
    sys.exit(1)


tab_e3t        = np.array(tab_e3t)
tab_prof       = np.array(tab_prof)
tab_prof_model = np.array(tab_prof_model)
## List input files
filelist = []
days     = []

for cdate in cla_dates :
    if cl_CL4type == 'CHL' :
        cl_filetmplt = lookfor+'_'+config_obs.upper()+'_'+config_model.upper()+'_rms_diff_'+cdate+'*nc'
    else :
        cl_filetmplt = config_model.upper()+'_'+grid_type+'_rms_diff_'+cdate+'*'+lookfor+'*nc'
    print "lookfor %s " %(cl_filetmplt)
    filelist_tmp = glob.glob(os.path.join(dircl4in,cl_filetmplt)) 
    if len(filelist_tmp) >1 :
        print 'too many files found at date %s' %cdate
        sys.exit(1)
    elif len(filelist_tmp) ==0:
        filelist_tmp = 'no_file.nc'
        filelist.append(filelist_tmp[0])
        days.append(cdate)            
    else :
        filelist.append(filelist_tmp[0])
        days.append(cdate)

if config_model.upper() == 'PSY3V2R2' :
        liste_region = np.chararray(11,itemsize=25)
        liste_region[:] = params.liste_zone[:11]
elif config_model.upper() in ['PSY3QV3R1','PSY3V3R2',\
                        'PSY4V1R3','PSY4V2R2','PSY4V3R1',\
                        'PSY3V3R3','BIOMER4'] :
        liste_region = np.chararray(14,itemsize=25)
        liste_region[:] = params.liste_zone[:14]
elif config_model.upper() in ['BLK','FOAM','GIOPS_CONCEPTS','PSY3V3R1','HYCOM','HYCOM_RTOFS'] :
        liste_region = np.chararray(13,itemsize=25)
        liste_region[:] = params.liste_zone[:13]
elif config_model.upper() in ['PSY4V2R1'] :
        liste_region = np.chararray(1,itemsize=25)
        liste_region[0] =  'GLO'
elif config_model.upper() in ['PSY2V4R1','PSY2V4R2','PSY2V4R3','PSY2V4R4','PSY2QV4R2'] :
        liste_region = np.chararray(6,itemsize=25)
        liste_region[:] = params.liste_zone[:]

# On cree des fichiers ascii avec les stats par zone et par jour :
# date num_obs mean_obs mean_hind mse_hind mean_f1 mse_f1 mean_f3 mse_f3 mean_f5 mse_f5
# a partir des fichiers netcdf rms_diff qui comportent eux les moyennes,biais, RMS (!!),RMSE(!!)
#attention : Les donnees dans les fichiers netcdf sont deja divisees par le nombre d'obs dans la boite


supobs.Statslib.calculer_stats_MYO2(file_boxmask,config_model.upper(),tab_prof,\
                        tab_prof_model,tab_e3t,variable_name_type,\
                        liste_region,filelist,cl_CL4type,\
                        days, dircl4in ,dircl4out,cl_dateMinZone,cl_dateMaxZone  ) 

supobs.Statslib.calculer_stats_all(file_boxmask,config_model.upper(),tab_prof,\
                        tab_prof_model,tab_e3t,variable_name_type,\
                        liste_region,filelist,cl_CL4type,\
                        days, dircl4in ,dircl4out,cl_dateMinZone,cl_dateMaxZone  ) 

