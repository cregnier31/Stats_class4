#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
import os,sys,string,shutil,glob,re
import subprocess,shlex

#===============================
# Test sur le nombre d'arguments
# ===============================
#python TEP_CLASS4_multiprocess.py --config=PSY4QV2R2 --daterun=20150201 --nbdate=1 --delta=0 --src=GODAE --data=aice

if len(sys.argv) != 8: 
  print 'Usage: ./Launch_stats_omp.py <config> <daterun> <nbdate> <delta> <src> <data> <nbprocs>' 
  print len(sys.argv)
  sys.exit(1) 
else :
  CONFIG=sys.argv[1]
  DATERUN=sys.argv[2]
  NBDATE=sys.argv[3]
  DELTA=sys.argv[4]
  SRC=sys.argv[5]
  DATA=sys.argv[6]
  NB_PROC=sys.argv[7]
if str(DATA) != "aice" : 
   print "Type valuable %s " %(type)

###
## Create configfile
dir="/home/ext/mr/smer/regnierc/SAVE/DEV/TEP_CLASS4_V4/script/"
DIR_SUB="/home/ext/mr/smer/regnierc/SAVE/DEV/TEP_CLASS4_V4/script/sub/"
sub=DIR_SUB+"launch_class4_"+CONFIG+"_"+DATERUN+"_mono.pbs"
dir_log="/home/ext/mr/smer/regnierc/SAVE/DEV/TEP_CLASS4_V4/log"
exe=dir+'TEP_CLASS4_multiprocess_prolix.py'
nproc=1
nproc2=1
nodes=2
MPIRUN="mpirun"
MYNODES=1
MYPPN=1
nproc=NB_PROC
MYPPN2=nproc
codexe = '%s --config %s --daterun=%s --nbdate=%s --delta=%s --src=%s --data=%s --typemod=pgn --nbproc=%s ' %(exe,CONFIG,DATERUN,NBDATE,DELTA,SRC,DATA,NB_PROC)
print codexe
## Create qsub job
obFichier=open(sub,'w+')
obFichier.write('#!/bin/ksh'+'\n')
obFichier.write('#SBATCH -A cmems'+'\n')
obFichier.write('#SBATCH -J CLASS4_AICE_'+CONFIG+'_'+DATERUN+'\n')
obFichier.write('#SBATCH -e '+dir_log+'/CLASS4_AICE_'+CONFIG+'_'+DATERUN+'.err'+'\n')
obFichier.write('#SBATCH -o '+dir_log+'/CLASS4_AICE_'+CONFIG+'_'+DATERUN+'.out'+'\n')
obFichier.write('#SBATCH -N 1'+'\n')
obFichier.write('#SBATCH -p normal64'+'\n')
obFichier.write('#SBATCH --mem 32768'+'\n')
obFichier.write('#SBATCH --ntasks-per-node='+str(nproc)+'\n')
obFichier.write('#SBATCH -t 6:30:00'+'\n')
obFichier.write('module load intel'+'\n')
obFichier.write('module load netcdf'+'\n')
obFichier.write('module load nco'+'\n')
obFichier.write(codexe+'\n')
obFichier.close()
SUBEXE="sbatch"
code_launch='%s %s ' %(SUBEXE,sub)
args   = shlex.split(code_launch)
print(args)
try :   subprocess.check_call(args)
except :
     print 'Launch %s failed' %sub
     sys.exit(1)
