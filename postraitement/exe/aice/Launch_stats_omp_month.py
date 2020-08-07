#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
import os,sys,string,shutil,glob,re
import subprocess,shlex

DIRDATA="/naviti/data5/cregnier/CLASS4_MERCATOR/PSY4V3R1/dezip/"
cl_path="/naviti/data5/cregnier/CLASS4_MERCATOR/PSY4V3R1/Stats/"
DIRDATA="/naviti/data2/cregnier/CLASS4_GODAE/"

#===============================
# Test sur le nombre d'arguments
# ===============================

if len(sys.argv) != 6: 
  print 'Usage: ./Launch_stats_omp.py <YEAR> <MONTH> <model> <zone> <type>' 
  sys.exit(1) 
else :
  YEAR=sys.argv[1]
  MONTH=sys.argv[2]
  model=sys.argv[3]
  zone=sys.argv[4]
  type=sys.argv[5]

if int(MONTH) < 10 : 
    MONTH="0"+MONTH
else: 
    MONTH=MONTH
cl_date=str(YEAR)+"_"+str(MONTH)
#model="GIOPS"
#model="PSY4"
#zone="ANT"
cl_path="/naviti/data5/cregnier/CLASS4_MERCATOR/"+model+"/Stats/"
rl_seuil=0.0
rl_seuil2=0.2
BIN_DIR="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/bin/"
exe=BIN_DIR+"Stats_CL4_aice_openmp_"+zone+".exe"
exe=BIN_DIR+"Stats_CL4_aice_openmp_contable_"+zone+".exe"
exe=BIN_DIR+"Stats_CL4_aice_openmp_contable_time_"+zone+".exe"
#exe==BIN_DIR+"/home/cregnier/DEV_naviti/CLASS4_aice/bin/Stats_CL4_aice_"+zone+".exe"
dir_log="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/exe/aice/log"
nml="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/NAMELIST/namelist_aice_"+zone+"_"+model+"_"+YEAR+MONTH+".nml"
sub="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/sub/launch_stats_"+zone+"_"+YEAR+MONTH+"_"+model+"_omp.pbs"
list_file=[]
for file in glob.glob(DIRDATA+"/class4_"+YEAR+MONTH+"*"+model+"*aice.nc") :
    list_file.append(file)
nbfile=len(list_file)
# Write namelist file
obFichier=open(nml,'w')
obFichier.write('&Liste_aice\n')
obFichier.write('il_nbfile        = '+str(nbfile)+'\n')
obFichier.write("cl_conf        = '"+str(model)+"'"+'\n')
obFichier.write("cl_date        = '"+str(cl_date)+"'"+'\n')
obFichier.write("cl_path        = '"+str(cl_path)+"'"+'\n')
obFichier.write("rl_seuil        = "+str(rl_seuil)+'\n')
obFichier.write("rl_seuil2        = "+str(rl_seuil2)+'\n')

obFichier.write('/'+'\n')
for file in list_file :
  obFichier.write(str(file)+'\n')
obFichier.close()
nproc=16
codexe = '%s -n %s -p %s -z %s' %(exe,nml,str(nproc),zone)

## Create qsub job
obFichier=open(sub,'w+')
obFichier.write('#PBS -N Stats_AICE_'+model+'_'+YEAR+MONTH+'\n')
obFichier.write('#PBS -e '+dir_log+'/Stats_CL4_'+zone+'_'+YEAR+MONTH+'_AICE.$PBS_JOBID.err'+'\n')
obFichier.write('#PBS -o '+dir_log+'/Stats_CL4_'+zone+'_'+YEAR+MONTH+'_AICE.$PBS_JOBID.out'+'\n')
obFichier.write('#PBS -l nodes=1:ppn=16'+'\n')
obFichier.write('#PBS -q mono'+'\n')
obFichier.write('#PBS -l walltime=6:00:00'+'\n')
obFichier.write('export OMP_NUM_THREADS=16'+'\n')
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
