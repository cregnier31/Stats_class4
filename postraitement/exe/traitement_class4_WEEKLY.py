#!/bin/python
# -*- coding: iso-8859-1 -*-
# Script de lancement du traitement des class4 en trimestriel
# C.REGNIER Avril 2010 : Creation
# C.REGNIER Juillet 2010 : Derniere version pour le bulletin trimestriel  
# C.REGNIER April 2012 : add logging function
# C.REGNIER April 2012 : merge ksh script lancer_CLASS4.ksh

import os,errno,sys,string,shutil,glob,re
## Beaufix path
#sys.path.append("/home/ext/mr/smer/regnierc/python/module")
## Local path
sys.path.append("/home/cregnier/python/module/")
sys.path.append("/home/qualif/CLASS4/python_mod")
sys.path.append("/home/cregnier/python/module/lib/python2.6/site-packages")
sys.path.append("/home/cregnier/python/module/lib/python2.7/site-packages/")
sys.path.append("/home/cregnier/python/module/lib/python2.7/site-packages/nco-0.0beta-py2.7.egg/")

from datetime import timedelta,datetime,date
from ModuleTime import Time
import ConfigParser
import resource
import shlex,subprocess
import logging
from array import *
from sytoolkit.sydate_origin import SyDateOrigin
from sytoolkit.sydate import SyDate


### Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
#
## Test input parameters
if len(sys.argv) != 4: 
   print 'Usage: traitement_class4.py <daterun> <MODELE_TYPE> <gridtype>' 
   sys.exit(1) 
else:
   DATERUN=sys.argv[1]
   MODELE_TYPE=sys.argv[2]
   GRID=sys.argv[3]
# =============
# CONFIGURATION
# =============

#_DBFILE_ = ['/home/ext/mr/smer/regnierc/SAVE/DEV/TEP_CLASS4_trunk/postraitement/exe/config_'+MODELE_TYPE+'.cfg']
_DBFILE_ = ['/sortref/reanalyse/glorys/phy/MATHIEU_HAMON/CLASS4/V3/postraitement/exe/config_'+MODELE_TYPE+'.cfg']
# =========
# FUNCTIONS
# =========
## Chargement de tous les éléments du fichier de configuration
def load_db():
    db = ConfigParser.ConfigParser()
    for file in _DBFILE_:
        db.read(os.path.expanduser(file))
    if not db.sections():
        print "Configuration file not found !"
        os._exit(1)
    return db

#
# ==========================================
# Chargement fichier de config
# ==========================================
db = load_db()

# ===============
# LOGGER
# ===============
logging.basicConfig(format='%(asctime)s %(message)s')
log = logging.getLogger("STATS_CLASS4")
## On Fixe le niveau d'erreur d'ecriture des logs
log.setLevel(logging.ERROR)
log.setLevel(logging.DEBUG)

## ==========================================
# Load parameters Chargement des parametres
## ==========================================

LISTE_VAR=db.get('GLOBAL','LISTEVAR').split()
output=db.get('output_dir','DIROUTPUT')
dir_CL4=db.get('input_dir','dir_CL4')
modele=db.get('GLOBAL','CONFIGURATION')
EXEDIR=db.get('GLOBAL','EXEDIR')
TYPERUN=db.get('GLOBAL','RUNTYPE')
DIR_LOG=db.get('GLOBAL','DIRLOG')
DIR_NAMELIST=db.get('GLOBAL','NAMELIST_DIR')
DIR_BIN=db.get('GLOBAL','DIRBIN')
File_BOXES=db.get('GLOBAL','FILEBOX')
DIR_utils=os.path.dirname(File_BOXES) 
DIR_CPT=db.get('GLOBAL','DIRCPTRD')
fic_boxes=os.path.basename(File_BOXES)
ficlog=db.get('GLOBAL','FILELOG')
ficsynth=db.get('GLOBAL','FILESYNTH')
ficbathy=db.get('GLOBAL','FILEBATHY')
fictype=db.get('GLOBAL','FILETYPE')
seuilbathy=db.get('GLOBAL','BATHYMIN')
seuiltemp=db.get('GLOBAL','TEMPMAX')
seuilsal=db.get('GLOBAL','SALMAX')
ficprof=db.get('GLOBAL','FICPROF')
zone=db.get('GLOBAL','ZONE')
TYPEDATANAME=db.get('GLOBAL','DATATYPE')

# ==========================================
#   Clean
# ==========================================
## rm link files boxes
if os.path.isfile(File_BOXES) :
   os.remove(File_BOXES)

#os.remove("Stats_coriolis"+"*")
if os.path.isfile("Test_coriolis.txt") : 
  os.remove("Test_coriolis.txt")
if os.path.isfile(DIR_LOG+'RejetProfilBathy.txt') :
  os.remove(DIR_LOG+'RejetProfilBathy.txt')
if os.path.isfile(DIR_LOG+'ResultStatBoite.txt') :
  os.remove(DIR_LOG+'ResultStatBoite.txt')  
if os.path.isfile(DIR_LOG+'ResultAnoTEMP.txt') :
  os.remove(DIR_LOG+'ResultAnoTEMP.txt')
if os.path.isfile(DIR_LOG+'ResultAnoPSAL.txt') :
  os.remove(DIR_LOG+'ResultAnoPSAL.txt')
#if os.path.isfile(DIR_LOG+ficlog) :
#  os.remove(DIR_LOG+ficlog)
if os.path.isfile(DIR_LOG+ficsynth) :
  os.remove(DIR_LOG+ficsynth)

# ==========================================
# En fonction du type de grille 
# Creation du répertoire de sortie
# Creation du lien vers la grille de tri des données
# ==========================================

if GRID ==  "0" :       
  dir_out=output+'/'    
  name="Region_boite_global.txt"
  GRIDTYPE='1'
elif GRID ==  "1" :
  dir_out=output+'/bins_1deg/'
  name="position_1deg.txt"
  GRIDTYPE='2'
elif GRID ==  "2" :
  dir_out=output+'/bins_2deg/'
  name="position_2deg.txt"
  GRIDTYPE='2'
elif GRID ==  "3" :
  dir_out=output+str(YEAR)+'_'+str(TRIM)+'/bins_3deg/'
  name="position_3deg.txt"
  GRIDTYPE='2'
elif GRID ==  "4" :
  dir_out=output+'/bins_4deg/'
  name="position_4deg.txt"
  GRIDTYPE='2'
else : 
   log.error("Grid type not known")
   sys.exit(1)

## Creation du repertoire de sortie
if not os.path.isdir(dir_out) :
  log.info('Creation repertoire  %s ' % (dir_out))
  os.makedirs(dir_out)
else:
  log.info('Repertoire existant  %s ' % (dir_out))

## Creation du repertoire de log
if not os.path.isdir(DIR_LOG) : 
  log.info('Creation repertoire log %s ' % (DIR_LOG))
  os.makedirs(DIR_LOG)
else:
  log.info('Repertoire existant  %s ' % (DIR_LOG))

#===================================================================================================
# En fonction du type de donnée insitu creation d'une variable TYPEDATA
# CORA et CORIOLIS possèdent un parameterint et ARMOR possède un PARAMETERINT et un parameterint2
#====================================================================================================

if TYPEDATANAME ==  "CORA" :       
  TYPEDATA="1"
  PREFIX="ext-CO" 
elif TYPEDATANAME ==  "CORIOLIS" :
  TYPEDATA="1"
  PREFIX="CO" 
elif TYPEDATANAME ==  "ARMOR" :
  TYPEDATA="2"
  PREFIX="CO" 
elif TYPEDATANAME ==  "ARMOR_RAW" :
  TYPEDATA="2"
  PREFIX="AR_CO"
else : 
   log.error("insitu data type not known")
   sys.exit(1)


# Creation du lien symbolique
try : 
   os.symlink(DIR_utils+'/'+name,DIR_utils+'/'+fic_boxes)
except OSError, e:
   if e.errno == errno.EEXIST:
       os.remove(DIR_utils+'/'+fic_boxes)
       os.symlink(DIR_utils+'/'+name,DIR_utils+'/'+fic_boxes)
# ==========================================
# Selection des fichiers de données in situ 
# ==========================================

Obj=Time()
julrun=Obj.d2j(DATERUN)
yyyy=DATERUN[:4]
date_run=SyDate(DATERUN)
presmonth=DATERUN[:6]
backmonth=SyDate.__str__(date_run.gobackward(30))[:6]

if  TYPERUN == "OPER" :
  julcorstart=julrun - 14
  julcorend=julrun - 8
else :
  julcorstart=julrun - 7
  julcorend=julrun - 1
dateini=Obj.j2d(julcorstart)
datefin=Obj.j2d(julcorend)
PeriodeName=dateini+'-'+datefin

log.info(" Periode Jour Min : %s Jour Max : %s" %(dateini,datefin))
log.info("-------------------------")
log.info("Select files with date and region ")
LISTFILE=dir_CL4+PREFIX+"_*"+backmonth+"*.nc"
files=[]
for fic in glob.glob(LISTFILE) :
  fic_bis=os.path.basename(fic)
  files.append(fic_bis)
LISTFILE2=dir_CL4+PREFIX+"_*"+presmonth+"*.nc"
for fic in glob.glob(LISTFILE2) :
   fic_bis=os.path.basename(fic)
   files.append(fic_bis)
  
log.info("Nombre de fichiers avant tri %i" %(len(files)))
#log.info("Fichiers :: %s "%(files))
new_files=[]

# ============================================
# Creation de la namelist des fichiers insitu
# ============================================

for object in files[:] :
       ## Cas Coriolis normal
       if TYPEDATANAME == "CORIOLIS" :
          datefic=int(Obj.d2j(object.split('_')[1]))
       elif TYPEDATANAME ==  "ARMOR" :
          datefic=int(Obj.d2j(object.split('_')[3].split('.')[0]))
       ## Cas ARMOR
       elif TYPEDATANAME ==  "ARMOR_RAW" :
          datefic=int(Obj.d2j(object.split('_')[4].split('.')[0]))
       ## Cas CORA
       elif TYPEDATANAME ==  "CORA" :
          datefic=int(Obj.d2j(object.split('_')[2].split('.')[0]))

       if datefic >= julcorstart and datefic <= julcorend :
         new_files.append(object)
   #      print " oK %s %s %s "  %(julcorstart,datefic,julcorend)
         #del files[indice]
log.info("Fichiers :: %s "%(new_files))
nb_fic=len(new_files)
log.info("Nombre de fichiers apres tri %i" %(nb_fic))
# Write namelist
fic_namelist=DIR_NAMELIST+"namelist_liste_corio.txt"
try:
  # Creation fichier
  obFichier=open(fic_namelist,'w')
  obFichier.write('&liste_corio\n')
  obFichier.write('il_nbfile= '+str(nb_fic)+'\n')
  obFichier.write('PATH= '+"'"+dir_CL4+"'"+'\n')
  obFichier.write('cd_LogFile= '+"'"+ficlog+"'"+'\n')
  obFichier.write('cd_SynthFile= '+"'"+ficsynth+"'"+'\n')
  obFichier.write('cl_bathyfile= '+"'"+ficbathy+"'"+'\n')
  obFichier.write('cl_bathytype= '+"'"+fictype+"'"+'\n')
  obFichier.write('rl_bathyseuil= '+seuilbathy+'\n')
  obFichier.write('rl_EcartTempMax= '+seuiltemp+'\n')
  obFichier.write('rl_EcartSalMax= '+seuilsal+'\n')
  obFichier.write('/'+'\n')
  for element in new_files:
      obFichier.write(element+'\n')
  obFichier.close()
except:
  log.error('Probleme d ecriture namelist')
  sys.exit(1)

log.info("----------------------------")
log.info("Ecriture Namelist class4 OK ")
log.info("----------------------------")

# ==========================================
# Creation namelist liste de paramètres
# ==========================================

taille_param=len(LISTE_VAR)
fic_namelist_param=DIR_utils+"/param_names.in"
try:
  # Creation fichier
  obFichier=open(fic_namelist_param,'w')
  obFichier.write('&liste_param\n')
  obFichier.write('il_nbparams = '+str(taille_param)+'\n')
  obFichier.write('/'+'\n')
  for i in LISTE_VAR :  
      obFichier.write(i+'\n')
  obFichier.close()
except:
 sys.exit(1)

log.info("----------------------------")
log.info("Ecriture Namelist param  OK  %s :" %(fic_namelist_param))
log.info("----------------------------")

#  obFichier.write(i+'\n')=[i for i in LISTE_VAR] 

# ==========================================
# Creation namelist liste des profondeurs
# ==========================================
LISTE_prof=db.get('data','e3t_0').split()
index=0
rl_sum=0
array_prof1=array('f')
array_prof2=array('f')
array_prof1.append(0)
for object in LISTE_prof[:-1] :
  rl_sum=rl_sum+float(LISTE_prof[index])
  array_prof1.append(rl_sum)
  index=index+1
rl_sum=0
index=0
rl_sum=0
for object in LISTE_prof[:] :
    rl_sum=rl_sum+float(LISTE_prof[index])
    array_prof2.append(rl_sum)
    index=index+1
#print array_prof1 
#print array_prof2

taille_tab=len(array_prof1)
try:
  # Creation fichier
  index=0
  obFichier=open(DIR_utils+'/'+ficprof,'w')
  obFichier.write(str(taille_tab)+'\n')
  for object in array_prof1[:] :
          obFichier.write(str(array_prof1[index])+'  ')
          obFichier.write(str(array_prof2[index])+'\n')
          index=index+1
  obFichier.close()
except: 
  log.error('Probleme d ecriture namelist')
  sys.exit(1)

log.info("----------------------------")
log.info("Ecriture Namelist depth  OK ")
log.info("----------------------------")

# =========================================
#  Create e3t_O
# =========================================
LISTE_prof.append(array_prof2[-1])
taille_tab=len(LISTE_prof)
try:
  # Creation fichier
  index=0
  obFichier=open(DIR_utils+'/e3t_0.in','w')
  obFichier.write(str(taille_tab)+'\n')
  for object in LISTE_prof[:] :
          obFichier.write(str(LISTE_prof[index])+'\n')
          index=index+1
  obFichier.close()
except:
  log.error('Probleme d ecriture namelist')
  sys.exit(1)

# =========================================
#  Create depth
# =========================================
DETPHT=db.get('data','deptht').split()
taille_depth=len(DETPHT)+1
DETPHT.append(DETPHT[-1])
try:
  # Creation fichier
  index=0
  obFichier=open(DIR_utils+'/deptht.in','w')
  obFichier.write(str(taille_depth)+'\n')
  for object in DETPHT :
          obFichier.write(str(DETPHT[index])+'\n')
          index=index+1
  obFichier.close()
except:
  log.error('Probleme d ecriture namelist')
  sys.exit(1)
# =========================================
#  Create files
# =========================================
obFichier=open(DIR_LOG+'RejetProfilBathy.txt','w')
obFichier.close()
obFichier=open(DIR_LOG+'ResultStatBoite.txt','w')
obFichier.close()
obFichier=open(DIR_LOG+'ResultAnoTEMP.txt','w')
obFichier.close()
obFichier=open(DIR_LOG+'ResultAnoPSAL.txt','w')
obFichier.close()

# ==========================================
# Launch CLASS4 Statistics
# ==========================================
log.info("---------------------------------")
log.info("    Calcul des stats class4      ")
log.info("---------------------------------")
code_lancement=DIR_BIN+'Lecture_class4.exe '+fic_namelist+' '+modele+' ' \
                +dir_out+' '+DATERUN+' '+GRIDTYPE+' '+DIR_LOG+' '+TYPEDATA \
                +' '+DIR_utils+'/'
try:
      args = shlex.split(code_lancement)
      log.info("%s" %args)
      log.info("Date de run n : %s %s "  % (str(julrun),str(DATERUN)))
      log.info("Jour Min Max : %s %s " % (str(dateini),str(datefin)))
#      os.chdir(EXEDIR) 
#      subprocess.check_call(args)
      os.system(code_lancement)
      log.info("Code OK  %s " % (str(julrun)))
except:
       log.error("Probleme execution %s " % (str(julrun)) )
       sys.exit(1)


log.info("---------------------------------")
log.info("    Renommage fichier de sortie  ")
log.info("---------------------------------")

if os.path.isfile(DIR_LOG+'ListeTEMPbadprof.txt') :
  shutil.move(DIR_LOG+'ListeTEMPbadprof.txt',DIR_CPT+'ListeTEMPbadprof_'+PeriodeName+'_'+modele+'_'+zone+'_gridtype'+GRID+'.txt')

if os.path.isfile(DIR_LOG+'ListePSALbadprof.txt') :
  shutil.move(DIR_LOG+'ListePSALbadprof.txt',DIR_CPT+'ListePSALbadprof_'+PeriodeName+'_'+modele+'_'+zone+'_gridtype'+GRID+'.txt')

if os.path.isfile(DIR_LOG+ficlog) :
   shutil.move(DIR_LOG+ficlog,DIR_CPT+'Lecture_class4_'+PeriodeName+'_'+modele+'_'+zone+'_gridtype'+GRID+'.log')

if os.path.isfile(DIR_LOG+ficsynth) :
   shutil.move(DIR_LOG+ficsynth,DIR_CPT+'Lecture_class4_'+PeriodeName+'_'+modele+'_'+zone+'_gridtype'+GRID+'.synth')

if os.path.isfile(DIR_LOG+'Bad_points_PSAL_CORIO.txt') :
   shutil.move(DIR_LOG+'Bad_points_PSAL_CORIO.txt',DIR_CPT+modele+'_R'+DATERUN+'_Bad_points_PSAL_CORIO.txt')

if os.path.isfile(DIR_LOG+'Bad_points_TEMP_CORIO.txt') :
   shutil.move(DIR_LOG+'Bad_points_TEMP_CORIO.txt',DIR_CPT+modele+'_R'+DATERUN+'_Bad_points_TEMP_CORIO.txt')

if os.path.isfile(DIR_LOG+'ResultStatBoite.txt') :
   shutil.move(DIR_LOG+'ResultStatBoite.txt',dir_out+'ResultStatBoite'+modele+'_'+zone+'_'+PeriodeName+'.txt')

if os.path.isfile(DIR_LOG+'RejetProfilBathy.txt') :
   shutil.move(DIR_LOG+'RejetProfilBathy.txt',dir_out+'RejProfBathy'+modele+'_'+zone+'_'+PeriodeName+'.txt')

if os.path.isfile(DIR_LOG+'ResultAnoTEMP.txt') :
   shutil.move(DIR_LOG+'ResultAnoTEMP.txt',dir_out+'AnoTEMP'+modele+'_'+zone+'_'+PeriodeName+'.txt')

if os.path.isfile(DIR_LOG+'ResultAnoPSAL.txt') :
   shutil.move(DIR_LOG+'ResultAnoPSAL.txt',dir_out+'AnoPSAL'+modele+'_'+zone+'_'+PeriodeName+'.txt')

log.info("-------  Renommage ok  ------------------")
## Lancement du run d'après
DAYMAX=db.get('GLOBAL','DAY_MAX')
HOMEDIR=db.get('GLOBAL','DIRHOME')
print 'DAYMAX %s ' %(DAYMAX) 
jmax=Obj.d2j(DAYMAX)
jrunext=julrun+7
print 'nextrun %s ' %(jrunext)
if  jrunext <= jmax :
   JRUN=Obj.j2d(jrunext)
   print 'Lancement du run %s ' %(JRUN)
   #code_lancement=HOMEDIR+'exe/Launch_Stat_CLASS4.ksh '+JRUN+' '+MODELE_TYPE+' '+GRID
   code_lancement='python '+HOMEDIR+'exe/traitement_class4_WEEKLY.py '+JRUN+' '+MODELE_TYPE+' '+GRID
   print code_lancement
   try:
        os.system(code_lancement)
        print "Lancement date run %s ok " % (JRUN)
   except:
      print 'Probleme execution'
      sys.exit(1)

else : 
  JRUN=Obj.j2d(jrunext)
  print 'Dépassement de JMAX : %s %s ' % (JRUN,DAYMAX)
  sys.exit(1)




