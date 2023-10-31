import os
import stat
import shutil
import logging
import glob,sys,re
import errno
from sytoolkit.sydate import SyDate
import time
from datetime import date
## Creation de la persistence pour une liste de jours
##
# ===============================
# Test sur le nombre d'arguments
# ===============================

if len(sys.argv) != 2:
  print ('Usage: Creat_pers.py <modeletype>')
  sys.exit(1)
else :
  modele_type=sys.argv[1]

config_h=modele_type
config_d=re.sub("V","QV",config_h)

# PSY4
type_d=config_d[0:5]
type=config_d[0:4]
# GLO12
type_d=config_d[0:6]
type=config_d[0:5]

day1=SyDate("20230801")
day2=SyDate("20231013")
JJMIN=day1.tojulian()
JJMAX=day2.tojulian()

config_type=modele_type.lower()
config_type_daily=config_d.lower()
print ("daily %s "%(config_type_daily))
print ("hebdo %s "%(config_type))
DIR_SORT = "/utmp/smer/regnierc/SORT-2/"
DIR_SORT_DAILY = DIR_SORT+"DAILY/"+type_d+"/"+config_type_daily
DIR_SORT_HEBDO = DIR_SORT+"HEBDO/"+type+"/"+config_type
print(DIR_SORT_DAILY)
print(DIR_SORT_HEBDO)
DIRPERS1=DIR_SORT_DAILY+"/pers1/"
DIRPERS2=DIR_SORT_DAILY+"/pers2/"
DIRPERS3=DIR_SORT_DAILY+"/pers3/"
DIRPERS4=DIR_SORT_DAILY+"/pers4/"
DIRPERS5=DIR_SORT_DAILY+"/pers5/"
DIRPERS6=DIR_SORT_DAILY+"/pers6/"
DIRPERS7=DIR_SORT_DAILY+"/pers7/"
DIRPERS8=DIR_SORT_DAILY+"/pers8/"
DIRPERS9=DIR_SORT_DAILY+"/pers9/"
DIR_NOWDAILY=DIR_SORT_DAILY+"/nwct/"
DIR_NOWHEBDO=DIR_SORT_HEBDO+"/nwct/"
DIR_NOWHEBDO=DIR_NOWDAILY
nb_files=(JJMAX-JJMIN)+1
print (nb_files)

config_d ="GLO12_ng"
config_h ="GLO12_ng"

while JJMIN <= JJMAX :
 day=SyDate.fromjulian(JJMIN)  
 print ("DAY %s " %(day))
 type_day=day.weekday
 nextday=day.goforward(1)
 pers1=day.gobackward(1)
 pers2=day.gobackward(2)
 pers3=day.gobackward(3)
 pers4=day.gobackward(4)
 pers5=day.gobackward(5)
 pers6=day.gobackward(6)
 pers7=day.gobackward(7)
 pers8=day.gobackward(8)
 pers9=day.gobackward(9)
 dayname = "1dAV"
 dayname = "1d-m"
 #file=DIR_NOWDAILY+config_d+"_1dAV_"+str(pers1)+"_*"
 file=f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers1}_*'
# liste_grid=["gridT", "gridS", "grid2D", "icemod", "gridU", "gridV"]
 liste_grid=["3DT-so", "3DT-thetao", "2DT", "2DU", "2DV"]
 liste_grid = ["0DT-oce", "2DT-ice", "2DT-oce", "2DU-ice", "2DU-oce", 
              "2DV-ice", "2DV-oce", "3DT-so", "3DT-thetao", "3DU-uo",
              "3DV-vo"]

 
#liste_grid=["icemod"] #,"gridU","gridV"]
 #liste_grid=["gridU","gridV"]
# liste_grid=["grid2D"]
 for grid in liste_grid:
   if type_day == 3 : 
       print ("thursday")
       lst_pers1=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers1}-*{grid}*')
       lst_pers8=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers8}-*{grid}*')
   else :
      lst_pers1=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers1}-*{grid}*')
      lst_pers8=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers8}-*{grid}*')
   if type_day == 4 :
       print ("friday")
       lst_pers1=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers1}-*{grid}*')
       lst_pers2=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers2}-*{grid}*')
       lst_pers9=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers9}-*{grid}*')
   else :
       lst_pers2=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers2}-*{grid}*')
       lst_pers9=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers9}-*{grid}*')
       print (f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers2}_*{grid}*')
   if type_day == 5 :
      print ("saturday")
      lst_pers3=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers3}-*{grid}*')
   else :
      lst_pers3=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers3}-*{grid}*')
   if type_day == 6 :
      print ("sunday")
      lst_pers4=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers4}-*{grid}*')
   else :
      lst_pers4=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers4}-*{grid}*')
   if type_day == 0 :
      print ("monday")
      lst_pers5=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers5}-*{grid}*')
   else :
      lst_pers5=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers5}-*{grid}*')
   if type_day == 1 :
      print ("monday")
      lst_pers6=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers6}-*{grid}*')
   else :
      lst_pers6=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers6}-*{grid}*')
   if type_day == 2 :
      print ("thuesday")
      lst_pers7=glob.glob(f'{DIR_NOWHEBDO}{config_h}_{dayname}_{pers7}-*{grid}*')
   else :
      lst_pers7=glob.glob(f'{DIR_NOWDAILY}{config_d}_{dayname}_{pers7}-*{grid}*')
   link_name_pers=f'{config_d}_{dayname}_{day}_{nextday}_{grid}_R{nextday}.nc'
   print(link_name_pers)
   print (lst_pers1)
   print (lst_pers2)
   for file in lst_pers1: 
## Create link pers1
      print ("file %s "  %(file))
      try :
         os.symlink(file,DIRPERS1+link_name_pers)
      except OSError as e:
        if e.errno == errno.EEXIST:
            os.remove(DIRPERS1+link_name_pers)
            os.symlink(file,DIRPERS1+link_name_pers)
   for file in lst_pers2:
## Create link pers1
      try:
         os.symlink(file,DIRPERS2+link_name_pers)
         print ("create link "+DIRPERS2+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS2+link_name_pers)
            os.symlink(file,DIRPERS2+link_name_pers)

   for file in lst_pers3:
## Create link pers3
      try: 
         os.symlink(file,DIRPERS3+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS3+link_name_pers)
            os.symlink(file,DIRPERS3+link_name_pers)

   for file in lst_pers4:
## Create link pers4
      try: 
         os.symlink(file,DIRPERS4+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS4+link_name_pers)
            os.symlink(file,DIRPERS4+link_name_pers)
 
   for file in lst_pers5:
## Create link pers5
      try:
         os.symlink(file,DIRPERS5+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS5+link_name_pers)
            os.symlink(file,DIRPERS5+link_name_pers)

   for file in lst_pers6:
## Create link pers6
      try: 
         os.symlink(file,DIRPERS6+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS6+link_name_pers)
            os.symlink(file,DIRPERS6+link_name_pers)

   for file in lst_pers7:
## Create link pers7
      try: 
         os.symlink(file,DIRPERS7+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS7+link_name_pers)
            os.symlink(file,DIRPERS7+link_name_pers)

   for file in lst_pers8:
## Create link pers8
      try: 
         os.symlink(file,DIRPERS8+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS8+link_name_pers)
            os.symlink(file,DIRPERS8+link_name_pers)

   for file in lst_pers9:
## Create link pers9
      try: 
         os.symlink(file,DIRPERS9+link_name_pers)
      except OSError as e:
         if e.errno == errno.EEXIST:
            os.remove(DIRPERS9+link_name_pers)
            os.symlink(file,DIRPERS9+link_name_pers)

 JJMIN=JJMIN+1
