#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
import os,sys,string,shutil,glob,re
import subprocess,shlex

#===============================
# Test sur le nombre d'arguments
# ===============================

if len(sys.argv) != 6: 
  print 'Usage: ./Launch_stats_total.py <YEAR> <model> <zone> <echeance> <type>' 
  print "type : serietemp1 serietemp2 index_skill 2Dstats skill_ts"
  print len(sys.argv)
  sys.exit(1) 
else :
  YEAR=sys.argv[1]
  model=sys.argv[2]
  zone=sys.argv[3]
  echeance=sys.argv[4]
  type=sys.argv[5]

cl_path="/naviti/data5/cregnier/CLASS4_MERCATOR/PSY4V3R1/Stats/"
if echeance != "fcst" and echeance != 'pers' and echeance != 'best' and echeance != "forecast" :
   print '%s not valuable' %(echeance)
   sys.exit(1)
DIR_HOME="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/"
DIR_EXE=DIR_HOME+"bin/"
DIR_SUB=DIR_HOME+"/postraitement/sub/"
dir_log=DIR_HOME+"/log"
DIR_NML=DIR_HOME+"nml/"

if type != "serietemp1"  and type != "serietemp2" and type != "index_skill" and type != "2Dstats" and type != "skill_ts":
   print "type unknown"
   print "Choose the following serietemp index_skill 2Dstats"

if type == "serietemp1" :
   exe=DIR_EXE+"compute_meantime.exe"
if type == "serietemp2" :
   if echeance == "best" :
     exe=DIR_EXE+"compute_meantime_hdct.exe"
     print "executable hdct"
   else :
     #exe=DIR_EXE+"compute_meantime.exe"
     exe=DIR_EXE+"compute_meantime_lead.exe"
if type == 'index_skill' :
   exe=DIR_EXE+"compute_index_skill.exe"
if type == "2Dstats":
   if echeance == "best" :
     exe=DIR_EXE+"compute_basic2D_stats_best.exe"
   else : 
     exe=DIR_EXE+"compute_basic2D_stats.exe"
if type == "skill_ts" :
   if echeance == "best" :
      exe=DIR_EXE+"compute_index_skill_timeseries_best.exe"
   else :
      exe=DIR_EXE+"compute_index_skill_timeseries.exe"

codexe = '%s -p %s -m %s -z %s -l %s -y %s' %(exe,cl_path,str(model),zone,echeance,str(YEAR))
sub=DIR_SUB+"launch_stats_mean.pbs"
## Create qsub job
obFichier=open(sub,'w+')
obFichier.write('#!/bin/ksh'+'\n')
obFichier.write('#PBS -N Meantime_'+model+'_'+YEAR+'_'+zone+'\n')
obFichier.write('#PBS -e '+dir_log+'/Meantime_'+model+'_'+YEAR+'_'+zone+'_'+echeance+'_'+type+'_AICE.err'+'\n')
obFichier.write('#PBS -o '+dir_log+'/Meantime_'+model+'_'+YEAR+'_'+zone+'_'+echeance+'_'+type+'AICE.out'+'\n')
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
