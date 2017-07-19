#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
import os,sys,string,shutil,glob,re
import subprocess,shlex

#===============================
# Test sur le nombre d'arguments
# ===============================

if len(sys.argv) != 4: 
  print 'Usage: ./Launch_stats_total.py <model> <zone> <echeance>' 
  print "type : /Launch_stats_region.py PSY4V3R1 ARC best"
  print len(sys.argv)
  sys.exit(1) 
else :
  model=sys.argv[1]
  zone=sys.argv[2]
  echeance=sys.argv[3]

print zone 
cl_path="/scratch/work/smer883/class4/"+model+"/stats_aice/"
if echeance != "fcst" and echeance != 'pers' and echeance != 'best' and echeance != "forecast" :
   print '%s not valuable' %(echeance)
   sys.exit(1)
DATE='JFM_2017'
DIR_HOME="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/"
DIR_MASK=DIR_HOME+"postraitement/src/aice/BOITE/MaskBoite_SIC_stereo_ARC.nc"
DIR_MACRO=DIR_HOME+"postraitement/src/aice/BOITE/MacroBoiteArctic.txt"
DIR_EXE=DIR_HOME+"bin/"
DIR_STATS="/naviti/data5/cregnier/CLASS4_MERCATOR/PSY4V3R1/Stats/"
DIR_SUB=DIR_HOME+"postraitement/sub/"
dir_log=DIR_HOME+"postraitement/log"
DIR_NML=DIR_HOME+"postraitement/nml/"
cl_fileout=DIR_STATS+"Stats_"+zone+"_"+model+"_"+DATE+"_"+echeance+"_boxes.nc"
if echeance != "best" :
    exe=DIR_EXE+"MCAL_SEAICE_STATS_lead.exe"
    echeance2 = echeance
else :
    print "Echeance best"
    exe=DIR_EXE+"MCAL_SEAICE_STATS.exe"
    echeance2 = echeance
    echeance = "fcst"
list_file=[]

for file in glob.glob(DIR_STATS+"/Stats_contable_"+zone+"_"+model+"*timeseries_aice_"+echeance+".nc") :
    list_file.append(file)
    print file
##liste_year=['2015','2016']
##list_month=['01','02','03','04','05','06','07','08','09','10','11','12']
##for year in liste_year :
##    for month in list_month : 
##	print year,month
##        #for file in sorted(glob.glob(DIR_STATS+"/Stats_contable_"+zone+"_"+model+"_"+year+"*timeseries_aice_"+echeance+".nc"),key=os.path.getmtime) :
##        for file in glob.glob(DIR_STATS+"/Stats_contable_"+zone+"_"+model+"_"+year+"_"+month+"*timeseries_aice_"+echeance+".nc") :
##           list_file.append(file)
##           print file

nml=DIR_NML+"namelist_aice_"+zone+"_"+model+"_"+echeance2+"_timeserie_zones.nml"
list_nml=[]
list_nml.append(nml)
nbfile=len(list_file)
# Write namelist file
obFichier=open(nml,'w')
obFichier.write('&Liste_aice\n')
obFichier.write('il_nbfile        = '+str(nbfile)+'\n')
obFichier.write("cl_conf        = '"+str(model)+"'"+'\n')
obFichier.write("cl_mask        = '"+str(DIR_MASK)+"'"+'\n')
obFichier.write("cl_file_boxes  = '"+str(DIR_MACRO)+"'"+'\n')
obFichier.write("cl_file_out        = '"+str(cl_fileout)+"'"+'\n')
obFichier.write("cl_echeance        = '"+str(echeance2)+"'"+'\n')
obFichier.write('/'+'\n')
for file in list_file :
   obFichier.write(str(file)+'\n')
obFichier.close()
print "file %s " %(list_file)
codexe = '%s -n %s' %(exe,nml)
sub=DIR_SUB+"launch_stats_mean_"+model+"_"+echeance2+".pbs"
## Create PBS job
obFichier=open(sub,'w+')
obFichier.write('#!/bin/ksh'+'\n')
obFichier.write('#PBS -N compute_stats_boxes_'+model+'_'+zone+'\n')
obFichier.write('#PBS -e '+dir_log+'/compute_stats_boxes_'+model+'_'+zone+'_'+echeance2+'_AICE.err'+'\n')
obFichier.write('#PBS -o '+dir_log+'/compute_stats_boxes_'+model+'_'+zone+'_'+echeance2+'_AICE.out'+'\n')
obFichier.write('#PBS -l nodes=1:ppn=1'+'\n')
obFichier.write('#PBS -q mono'+'\n')
obFichier.write('#PBS -l walltime=1:00:00'+'\n')
obFichier.write(codexe+'\n')
obFichier.close()
SUBEXE="/opt/torque/bin/qsub"
code_launch='%s %s ' %(SUBEXE,sub)
args   = shlex.split(code_launch)
print(args)
try :   subprocess.check_call(args)
except :
     print 'Launch %s failed' %sub
     sys.exit(1)
