#!/bin/python
# -*- coding: iso-8859-1 -*-
# Script de lancement du traitement des class4 en trimestriel
# C.REGNIER Avril 2010 : Creation
# C.REGNIER Juillet 2010 : Derniere version pour le bulletin trimestriel  
# C.REGNIER April 2012 : add logging function
# C.REGNIER April 2012 : merge ksh script lancer_CLASS4.ksh

import os,errno,sys,string,shutil,glob,re
from datetime import timedelta,datetime,date
from ModuleTime import Time
import configparser
import resource
import shlex,subprocess
import logging
from array import *
from sytoolkit.sydate import SyDate


### Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
#
## Test input parameters
if len(sys.argv) == 5:
    DATERUN=sys.argv[1]
    MODELE_TYPE=sys.argv[2]
    GRID=sys.argv[3]
    MACHINE=sys.argv[4]
    ll_debug = False
elif len(sys.argv) == 6:
    DATERUN=sys.argv[1]
    MODELE_TYPE=sys.argv[2]
    GRID=sys.argv[3]
    MACHINE=sys.argv[4]
    for o in sys.argv[1:]:
        if o in ['-d']:
            ll_debug = True
else:
    print('Usage: traitement_class4.py <daterun> <MODELE_TYPE> <gridtype><Machine>') 
    print (len(sys.argv))
    sys.exit(1)
# =============
# CONFIGURATION
# =============

HOMEDIR = os.path.dirname(os.path.realpath(__file__))
_DBFILE_ = [HOMEDIR+'/cfg/config_'+MODELE_TYPE+'.cfg']
# =========
# FUNCTIONS
# =========
## Chargement de tous les éléments du fichier de configuration
def load_db():
    db = configparser.ConfigParser()
    for file in _DBFILE_:
        db.read(os.path.expanduser(file))
    if not db.sections():
        print("Configuration file not found !")
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
#EXEDIR=db.get('GLOBAL','EXEDIR')
TYPERUN=db.get('GLOBAL','RUNTYPE')
DIR_LOG=db.get('GLOBAL','DIRLOG')
DIR_NAMELIST = HOMEDIR + '/../../NAMELIST/'
DIR_BIN=db.get('GLOBAL','DIRBIN')
#File_BOXES=db.get('GLOBAL','FILEBOX')
File_BOXES = HOMEDIR + "/../utils/File_boxes.txt"
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
if ll_debug:
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
    if os.path.isfile(DIR_LOG+ficlog) :
      os.remove(DIR_LOG+ficlog)
    if os.path.isfile(DIR_LOG+ficsynth) :
      os.remove(DIR_LOG+ficsynth)

# ==========================================
# En fonction du type de grille 
# Creation du répertoire de sortie
# Creation du lien vers la grille de tri des données
# ==========================================

if GRID ==  "1" :
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
elif TYPEDATANAME ==  "CORA4.1" :
  TYPEDATA="1"
  PREFIX="CO" 
  print("Cora4.1")
elif TYPEDATANAME ==  "CORA5.2" :
  TYPEDATA="1"
  PREFIX="CO" 
  print("Cora5.2")
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
except OSError as e:
   if e.errno == errno.EEXIST:
       os.remove(DIR_utils+'/'+fic_boxes)
       os.symlink(DIR_utils+'/'+name,DIR_utils+'/'+fic_boxes)
# ==========================================
# Selection des fichiers de données in situ 
# ==========================================

Obj=Time()
DATERUN_INI = DATERUN + "0101"
DATERUN_END = DATERUN + "1231"
julcorstart = Obj.d2j(DATERUN_INI)
julcorend = Obj.d2j(DATERUN_END)
dateini = DATERUN_INI
datefin = DATERUN_END
PeriodeName=dateini+'-'+datefin

log.info(" Periode Jour Min : %s Jour Max : %s" %(dateini,datefin))
log.info("-------------------------")
log.info("Select files with date and region ")
LISTFILE=dir_CL4+PREFIX+"_*"+DATERUN+"*.nc"
files=[]
for fic in glob.glob(LISTFILE) :
  fic_bis=os.path.basename(fic)
  files.append(fic_bis)
if TYPEDATANAME ==  "CORA" :
  TYPEDATA="1"
  PREFIX="ext-CO"

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
       elif TYPEDATANAME ==  "CORA4.1" or TYPEDATANAME ==  "CORA5.2":
          datefic=int(Obj.d2j(object.split('_')[2].split('.')[0]))
       if datefic >= julcorstart and datefic <= julcorend :
         new_files.append(object)
   #      print " oK %s %s %s "  %(julcorstart,datefic,julcorend)
         #del files[indice]
log.info("Fichiers :: %s "%(new_files))
nb_fic=len(new_files)
log.info("Nombre de fichiers apres tri %i" %(nb_fic))
ficlog=re.sub('.log','_'+TYPEDATANAME+"_"+modele+"_gridtype"+GRID+"_R"+str(DATERUN)+'.log',ficlog)
ficsynth=re.sub('.synth','_'+TYPEDATANAME+"_"+modele+"_gridtype"+GRID+"_R"+str(DATERUN)+'.synth',ficlog)
# Write namelist
fic_namelist=DIR_NAMELIST+"namelist_liste_corio_"+TYPEDATANAME+"_"+str(DATERUN)+".txt"
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
#fic_namelist_param=DIR_utils+"/param_names_"+modele.lower()+".in"
fic_namelist_param = DIR_utils+"/param_names_"+modele+".in"
log.info("Namelist param {}".format(fic_namelist_param))
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
    log.error("Write error param ")
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
if ll_debug:
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
      log.info(f"Date de run {DATERUN}")
      log.info(f"Jour Min Max {dateini} {datefin}")
      os.system(code_lancement)
      log.info(f"Code OK  {DATERUN}")
except:
       log.error(f"Probleme execution {DATERUN}")
       sys.exit(1)


log.info("---------------------------------")
log.info("    Renommage fichier de sortie  ")
log.info("---------------------------------")

if os.path.isfile(DIR_LOG+'ListeTEMPbadprof.txt') :
  shutil.move(DIR_LOG+'ListeTEMPbadprof.txt',DIR_CPT+'ListeTEMPbadprof_'+PeriodeName+'_'+modele+'_'+zone+'_gridtype'+GRID+'.txt')

if os.path.isfile(DIR_LOG+'ListePSALbadprof.txt') :
  shutil.move(DIR_LOG+'ListePSALbadprof.txt',DIR_CPT+'ListePSALbadprof_'+PeriodeName+'_'+modele+'_'+zone+'_gridtype'+GRID+'.txt')

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
