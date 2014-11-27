#!/bin/python
# -*- coding: iso-8859-1 -*-
# Script de lancement du traitement des class4 en trimestriel
# C.REGNIER Avril 2010 : Creation
# C.REGNIER Juillet 2010 : Derniere version pour le bulletin trimestriel  
import os,sys,string,shutil,glob
sys.path.append("/home/qualif/CLASS4/python_mod")
from datetime import timedelta,datetime,date
from ModuleTime import Time
import ConfigParser
import shlex,subprocess
#
if len(sys.argv) != 5: 
   print 'Usage: traitement_class4.py <jour1> <jour2> <MODELE_TYPE> <gridtype>' 
   sys.exit(1) 
else:
   JOUR1=str(sys.argv[1])
   JOUR2=str(sys.argv[2])
   MODELE_TYPE=sys.argv[3]
   GRID=sys.argv[4]

# =============
# CONFIGURATION
# =============
_DBFILE_ = ['config_'+MODELE_TYPE+'.cfg']
 
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
## Recherche du mercredi le plus proche
def first_wed_on_or_after(dt):
       days_to_go = 2 - dt.weekday()
       if days_to_go:
          dt += timedelta(days_to_go)
       return dt

#
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
## Recherche de toutes les dates de run pour un trimestre donné
def daterun_trim(year,trim):
        if trim  == 1: mois=[1,2,3]
        elif trim == 2: mois=[4,5,6]
        elif trim == 3: mois=[7,8,9]
        elif trim == 4: mois=[10,11,12]
        else: 
           print "Your input has not been recognised %s " % (trim)
           sys.exit(1)
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

# ==========================================
# Lancement du traitement class4
# ==========================================
#
# Chargement des parametres
output=db.get('output_dir','DIROUTPUT')
dir_CL4=db.get('input_dir','dir_CL4')
modele=db.get('GLOBAL','CONFIGURATION')
EXEDIR=db.get('GLOBAL','EXEDIR')
TYPERUN=db.get('GLOBAL','RUNTYPE')
DIR_LOG=db.get('GLOBAL','DIRLOG')

if GRID ==  "0" :
  dir_out=output+str(JOUR1)+'_'+str(JOUR2)+'/'
elif GRID ==  "1" :
  dir_out=output+str(JOUR1)+'_'+str(JOUR2)+'/bins_1deg/'
elif GRID ==  "2" :
  dir_out=output+str(JOUR1)+'_'+str(JOUR2)+'/bins_2deg/'
elif GRID ==  "4" :
  dir_out=output+str(JOUR1)+'_'+str(JOUR2)+'/bins_4deg/'
else : 
   print 'Type non reconnu'
   sys.exit(1)


print '-------------------------'
print 'Calcul des stats class4    '
print '-------------------------'

Obj=Time()
juljour1=Obj.d2j(JOUR1)
juljour2=Obj.d2j(JOUR2)
i=juljour1

while i <= juljour2 : 
   daterun=Obj.j2d(i)
   # Boucle sur les dates de run 
   code_lancement=EXEDIR+'lancer_class4_DAILY.ksh '+modele+' T '+daterun+' '+dir_CL4+' '+dir_out+' '+GRID+' '+DIR_LOG
   try:
     args = shlex.split(code_lancement)
     print args
     subprocess.check_call(args)
     print "Date de run n : %s %s "  % (str(i),str(daterun)) 
   except :
     print 'Probleme execution %s ' % (str(daterun))
     sys.exit() # exit the program
   i+=1

