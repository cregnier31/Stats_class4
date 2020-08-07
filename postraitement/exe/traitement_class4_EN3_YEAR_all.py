#!/bin/python
# -*- coding: iso-8859-1 -*-
# Script de lancement du traitement des class4 en trimestriel
# C.REGNIER Avril 2010 : Creation
# C.REGNIER Juillet 2010 : Derniere version pour le bulletin trimestriel  
# C.REGNIER April 2012 : add logging function
# C.REGNIER April 2012 : merge ksh script lancer_CLASS4.ksh

import os,sys,string,shutil,glob,re
sys.path.append("/home/qualif/CLASS4/python_mod")
from datetime import timedelta,datetime,date
from ModuleTime import Time
import ConfigParser
import resource
import shlex,subprocess
import logging
from array import *


### Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
#
## Test input parameters
if len(sys.argv) != 4: 
   print 'Usage: traitement_class4.py <year> <MODELE_TYPE> <gridtype>' 
   sys.exit(1) 
else:
   YEAR=int(sys.argv[1])
   MODELE_TYPE=sys.argv[2]
   GRID=sys.argv[3]

# =============
# CONFIGURATION
# =============

_DBFILE_ = ['/home/qualif/CLASS4/Lecture_Class4_V2.0/exe/config_'+MODELE_TYPE+'_EN3.cfg']

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


## Recherche du mercredi d'après 
def first_wed_after(dt):
       days_to_go = 2 - dt.weekday()
       if days_to_go >= 0:
          dt += timedelta(days_to_go)
       else :
          days_to_go2=days_to_go+7
          dt += timedelta(days_to_go2)
       return dt
#
## Recherche de toutes les dates de run pour une année donnée
def daterun_year(year):
        mois=[1,2,3,4,5,6,7,8,9,10,11,12]
        tab_date=[]
        for month in mois:
         dststart=datetime(year,month,1)
         start = first_wed_after(dststart)
         date=start
         month=date.month
         i=month
         tab_date.append(start.strftime("%Y%m%d"))
         while i == month :
            date2=date+timedelta(14)
            date+=timedelta(7)
            i=date2.month
            tab_date.append(date.strftime("%Y%m%d"))

        return tab_date
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
DIR_CPT=db.get('GLOBAL','DIRCPTRD_EN3')
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

# ==========================================
#   Clean
# ==========================================
## rm link files boxes
if os.path.isfile(File_BOXES) :
   os.remove(File_BOXES)

#os.remove("Stats_coriolis"+"*")
if os.path.isfile("Test_coriolis.txt") : 
  os.remove("Test_coriolis.txt")
if os.path.isfile(EXEDIR+'RejetProfilBathy.txt') :
  os.remove(EXEDIR+'RejetProfilBathy.txt')
if os.path.isfile(EXEDIR+'ResultStatBoite.txt') :
  os.remove(EXEDIR+'ResultStatBoite.txt')  
if os.path.isfile(EXEDIR+'ResultAnoTEMP.txt') :
  os.remove(EXEDIR+'ResultAnoTEMP.txt')
if os.path.isfile(EXEDIR+'ResultAnoPSAL.txt') :
  os.remove(EXEDIR+'ResultAnoPSAL.txt')
#if os.path.isfile(EXEDIR+ficlog) :
#  os.remove(EXEDIR+ficlog)
if os.path.isfile(EXEDIR+ficsynth) :
  os.remove(EXEDIR+ficsynth)

# ==========================================
# En fonction du type de grille 
# Creation du répertoire de sortie
# Creation du lien vers la grille de tri des données
# ==========================================
if GRID ==  "0" :       
  dir_out=output+str(YEAR)+'/'    
  name="Region_boite_global.txt"
  GRIDTYTPE='1'
elif GRID ==  "1" :
  dir_out=output+str(YEAR)+'/bins_1deg/'
  name="position_1deg.txt"
  GRIDTYTPE='2'
elif GRID ==  "2" :
  dir_out=output+str(YEAR)+'/bins_2deg_new/'
  name="position_2deg.txt"
  GRIDTYTPE='2'
elif GRID ==  "4" :
  dir_out=output+str(YEAR)+'/bins_4deg_new/'
  name="position_4deg.txt"
  GRIDTYTPE='2'
else : 
   log.error("Grid type not known")
   sys.exit(1)

# Creation du lien symbolique
os.symlink(DIR_utils+'/'+name,DIR_utils+'/'+fic_boxes)

# ==========================================
# Selection des fichiers de données et 
# création de la namelist
# ==========================================
i=0
for DATERUN in daterun_year(YEAR):
 i=i+1
 #if i > 5 and i <=18 :
 if i > 35 :
   print DATERUN
   Obj=Time()
   julrun=Obj.d2j(DATERUN)
   if  TYPERUN == "OPER" :
     julcorstart=julrun - 14
     julcorend=julrun - 8
   else :
     julcorstart=julrun - 7
     julcorend=julrun - 1
   dateini=Obj.j2d(julcorstart)
   datefin=Obj.j2d(julcorend)
   PeriodeName=dateini+'-'+datefin
   month_ini=dateini[:6]
   month_final=datefin[:6]
   log.info(" Periode Jour Min : %s Jour Max : %s" %(dateini,datefin))
   log.info("-------------------------")
   log.info("Select files with date and region ")
   #if MODELE_TYPE == "PSY2V4R2" :
   #  files=os.listdir(glob.glob(dir_CL4+"*_"+zone+"*.nc"))
   #files_tmp=glob.glob(dir_CL4+"*_"+zone+"*.nc")
   if month_ini == month_final :  
      files_tmp=glob.glob(dir_CL4+"EN3_v2a_Profiles_"+month_ini+"*.nc")
   else : 
      files_tmp1=glob.glob(dir_CL4+"EN3_v2a_Profiles_"+month_ini+"*.nc")
      files_tmp2=glob.glob(dir_CL4+"EN3_v2a_Profiles_"+month_final+"*.nc")
      files_tmp=[]
      files_tmp=files_tmp1
      for object in files_tmp2 :
          files_tmp.append(object)
   #   print "OK2 %s %s" %(month_ini,month_final)
   files=[]
   for fic in files_tmp :
     fic_bis=os.path.basename(fic)
     files.append(fic_bis)
  # else :
  #   files=os.listdir(dir_CL4)
   log.info("Nombre de fichiers avant tri %i" %(len(files)))
   #log.info("Fichiers :: %s "%(files))
   new_files=[]
   for object in files[:] :
     #    print " File %s "  %(object)
         datefic=int(Obj.d2j(object.split('_')[3]))
         print "Date %s %s %s "  %(julcorstart,datefic,julcorend)
         if datefic >= julcorstart and datefic <= julcorend :
            new_files.append(object)
   #         print " oK %s %s %s %s "  %(julcorstart,datefic,julcorend,object)
   #	 print ' fichier %s ' % (object)
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
   # Create Namelist list depth
   # ==========================================
   array_prof1=array('d',[0.0000000, 1.0224840, 2.0964121, 3.2331602, 4.4466161, 5.7537318, 7.1751977, 8.7362619, 10.4677290, 12.4071731, 14.6004119, \
   17.1032957, 19.9838731, 23.3250111, 27.2275555, 31.8141320, 37.2337047, 43.6670159, 51.3330456, 60.4966288, 71.4773637, 84.6599188, \
   100.5057943, 119.5665089, 142.4980331, 170.0760849, 203.2115936, 242.9652374, 290.5594529, 347.3857259, 415.0043825, 495.1336123, 589.6242935, \
   700.4175845, 829.4834844, 978.7408037, 1149.9621728, 1344.6714069, 1564.0439014, 1808.8226415, 2079.2619014, 2375.1074069, 2695.6161728, 3039.6128037, \
   3405.5734844, 3791.7255845, 4196.1502935, 4616.8776123, 5051.9663825, 5499.5657259])
   array_prof2=array('d',[1.0224840, 2.0964121, 3.2331602, 4.4466161, 5.7537318, 7.1751977, 8.7362619, 10.4677290, 12.4071731, 14.6004119, \
   17.1032957, 19.9838731, 23.3250111, 27.2275555, 31.8141320, 37.2337047, 43.6670159, 51.3330456, 60.4966288, 71.4773637, 84.6599188, \
   100.5057943, 119.5665089, 142.4980331, 170.0760849, 203.2115936, 242.9652374, 290.5594529, 347.3857259, 415.0043825, 495.1336123, 589.6242935, \
   700.4175845, 829.4834844, 978.7408037, 1149.9621728, 1344.6714069, 1564.0439014, 1808.8226415, 2079.2619014, 2375.1074069, 2695.6161728, 3039.6128037, \
   3405.5734844, 3791.7255845, 4196.1502935, 4616.8776123, 5051.9663825, 5499.5657259, 5957.9574529])
   
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
   #  Create files
   # =========================================
   obFichier=open(EXEDIR+'RejetProfilBathy.txt','w')
   obFichier.close()
   obFichier=open(EXEDIR+'ResultStatBoite.txt','w')
   obFichier.close()
   obFichier=open(EXEDIR+'ResultAnoTEMP.txt','w')
   obFichier.close()
   obFichier=open(EXEDIR+'ResultAnoPSAL.txt','w')
   obFichier.close()
   
   # ==========================================
   # Launch CLASS4 Statistics
   # ==========================================
   log.info("---------------------------------")
   log.info("    Calcul des stats class4      ")
   log.info("---------------------------------")
   
   code_lancement=DIR_BIN+'Lecture_class4_FRCST_EN3.exe '+fic_namelist+' '+modele+' '+dir_out+' '+DATERUN+' '+GRIDTYTPE+' '+DIR_LOG
   
   try:
         args = shlex.split(code_lancement)
         log.info("%s" %args)
         log.info("Date de run n : %s %s "  % (str(julrun),str(DATERUN)))
         log.info("Jour Min Max : %s %s " % (str(dateini),str(datefin)))
         os.chdir(EXEDIR) 
         subprocess.check_call(args)
         log.info("Code OK  %s " % (str(julrun)))
   except:
          log.error("Probleme execution %s " % (str(julrun)) )
          sys.exit(1)
   
   
   log.info("---------------------------------")
   log.info("    Renommage fichier de sortie  ")
   log.info("---------------------------------")
   
   if os.path.isfile(EXEDIR+'ListeTEMPbadprof.txt') :
     shutil.move(EXEDIR+'ListeTEMPbadprof.txt',DIR_CPT+'ListeTEMPbadprof_'+PeriodeName+'_'+modele+'_'+zone+'_EN3_gridtype'+GRID+'.txt')
   
   if os.path.isfile(EXEDIR+'ListePSALbadprof.txt') :
     shutil.move(EXEDIR+'ListePSALbadprof.txt',DIR_CPT+'ListePSALbadprof_'+PeriodeName+'_'+modele+'_'+zone+'_EN3_gridtype'+GRID+'.txt')
   
   if os.path.isfile(EXEDIR+ficlog) :
      shutil.move(EXEDIR+ficlog,DIR_CPT+'Lecture_class4_'+PeriodeName+'_'+modele+'_'+zone+'_EN3_gridtype'+GRID+'.log')
   
   if os.path.isfile(EXEDIR+ficsynth) :
      shutil.move(EXEDIR+ficsynth,DIR_CPT+'Lecture_class4_'+PeriodeName+'_'+modele+'_'+zone+'_EN3_gridtype'+GRID+'.synth')
   
   if os.path.isfile(EXEDIR+'Bad_points_PSAL_EN3.txt') :
      shutil.move(EXEDIR+'Bad_points_PSAL_EN3.txt',DIR_CPT+modele+'_R'+DATERUN+'_Bad_points_PSAL_EN3.txt')
   
   if os.path.isfile(EXEDIR+'Bad_points_TEMP_EN3.txt') :
      shutil.move(EXEDIR+'Bad_points_TEMP_EN3.txt',DIR_CPT+modele+'_R'+DATERUN+'_Bad_points_TEMP_EN3.txt')
   
   if os.path.isfile(EXEDIR+'ResultStatBoite.txt') :
      shutil.move(EXEDIR+'ResultStatBoite.txt',dir_out+'ResultStatBoite_EN3_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'RejetProfilBathy.txt') :
      shutil.move(EXEDIR+'RejetProfilBathy.txt',dir_out+'RejProfBathy_EN3_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'ResultAnoTEMP.txt') :
      shutil.move(EXEDIR+'ResultAnoTEMP.txt',dir_out+'AnoTEMP_EN3_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'ResultAnoPSAL.txt') :
      shutil.move(EXEDIR+'ResultAnoPSAL.txt',dir_out+'AnoPSAL_EN3_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'Test_coriolis_SAL.txt') :
      util.move(EXEDIR+'Test_coriolis_SAL.txt',dir_out+'Position_HDCST_PSAL_EN3_prof_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'Test_coriolis_SALLEV.txt') :
      util.move(EXEDIR+'Test_coriolis_SALLEV.txt',dir_out+'Position_SMLEV_EN3_prof_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'Test_coriolis_TEMP.txt') :
      util.move(EXEDIR+'Test_coriolis_TEMP.txt',dir_out+'Position_HDCST_TEMP_EN3_prof_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'Test_coriolis_TEMPLEV.txt') :
      util.move(EXEDIR+'Test_coriolis_TEMPLEV.txt',dir_out+'Position_TMLEV_EN3_prof_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'Test_coriolis_TEMP_FORECAST6D.txt') :
      util.move(EXEDIR+'Test_coriolis_TEMP_FORECAST6D.txt',dir_out+'Position_FRCST6D_TEMP_EN3_prof_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   if os.path.isfile(EXEDIR+'Test_coriolis_SAL_FORECAST6D.txt') :
      util.move(EXEDIR+'Test_coriolis_SAL_FORECAST6D.txt',dir_out+'Position_FRCST6D_PSAL_EN3_prof_'+modele+'_'+zone+'_'+PeriodeName+'.txt')
   
   log.info("-------  Renommage ok  ------------------")
   
sys.exit(0)





