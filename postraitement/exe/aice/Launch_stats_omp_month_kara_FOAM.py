#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
import os,sys,string,shutil,glob,re
import subprocess,shlex

DIRDATA="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/FOAM/data_CLASS4_GODAE/aice/"
#===============================
# Test sur le nombre d'arguments
# ===============================

if len(sys.argv) != 6: 
  print 'Usage: ./Launch_stats_omp.py <YEAR> <MONTH> <model> <zone> <leadtype>' 
  sys.exit(1) 
else :
  YEAR=sys.argv[1]
  MONTH=sys.argv[2]
  model=sys.argv[3]
  zone=sys.argv[4]
  leadtype=sys.argv[5]

if int(MONTH) < 10 : 
    MONTH="0"+MONTH
else: 
    MONTH=MONTH
cl_date=str(YEAR)+"_"+str(MONTH)
#model="GIOPS"
#model="PSY4"
#zone="ANT"
cl_path="/kara/data1/cregnier/CLASS4_MERCATOR/"+model+"/Stats/"
cl_dirmask="/kara/data1/cregnier/static/"
rl_seuil=0.4
rl_seuil=0.2
rl_seuil2=0.15
il_echeances=6
BIN_DIR="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/bin/"
machine="kara"
#exe=BIN_DIR+"Stats_CL4_aice_openmp_"+zone+".exe"
#exe=BIN_DIR+"Stats_CL4_aice_openmp_contable_"+zone+".exe"
#exe=BIN_DIR+"Stats_CL4_aice_openmp_contable_time_"+zone+".exe"
#exe=BIN_DIR+"Compute_seaice_stats_"+zone+"_naviti_leadtime.exe"
exe=BIN_DIR+"Compute_seaice_stats_"+zone+"_"+machine+"_leadtime.exe"
#exe==BIN_DIR+"/home/cregnier/DEV_naviti/CLASS4_aice/bin/Stats_CL4_aice_"+zone+".exe"
dir_log="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/exe/aice/log"
nml="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/NAMELIST/namelist_aice_"+zone+"_"+model+"_"+YEAR+MONTH+".nml"
sub="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/sub/launch_stats_"+zone+"_"+YEAR+MONTH+"_"+model+"_omp.pbs"
list_file=[]
for file in sorted(glob.glob(DIRDATA+"/class4_"+YEAR+MONTH+"*"+model+"*aice.nc")) :
    list_file.append(file)
if not list_file : 
    print "None in the list"
    sys.exit(1)
nbfile=len(list_file)
# Write namelist file
obFichier=open(nml,'w')
obFichier.write('&Liste_aice\n')
obFichier.write('il_nbfile        = '+str(nbfile)+'\n')
obFichier.write("cl_conf        = '"+str(model)+"'"+'\n')
obFichier.write("cl_path        = '"+str(cl_dirmask)+"'"+'\n')
obFichier.write("cl_stats_dir   = '"+str(cl_path)+"'"+'\n')
obFichier.write("rl_seuil        = "+str(rl_seuil)+'\n')
obFichier.write("rl_seuil2        = "+str(rl_seuil2)+'\n') 
obFichier.write("il_echeance    = "+str(il_echeances)+'\n')

obFichier.write('/'+'\n')
for file in list_file :
  obFichier.write(str(file)+'\n')
obFichier.close()
nproc=16
codexe = '%s -n %s -z %s -f %s' %(exe,nml,zone,str(leadtype))

## Create qsub job
obFichier=open(sub,'w+')
obFichier.write('#!/bin/ksh'+'\n')
obFichier.write('#############################'+'\n')
obFichier.write('#SBATCH -J Stats_AICE_'+model+'_'+YEAR+MONTH+'\n')
obFichier.write('#SBATCH -e '+dir_log+'/Stats_CL4_'+zone+'_'+YEAR+MONTH+'_AICE_%j.err'+'\n')
obFichier.write('#SBATCH -o '+dir_log+'/Stats_CL4_'+zone+'_'+YEAR+MONTH+'_AICE.%j.out'+'\n')
obFichier.write('#SBATCH -N 1'+'\n')
obFichier.write('#SBATCH --ntasks-per-node=16'+'\n')
obFichier.write('#SBATCH -p mono'+'\n')
obFichier.write('#SBATCH --time=3:00:00'+'\n')
obFichier.write('#SBATCH --exclusive'+'\n')
obFichier.write('module load intel/intel-18'+'\n')
obFichier.write('module load netcdf/netcdf-4.4.1_intel18_hdf5'+'\n')
obFichier.write('export OMP_NUM_THREADS=16'+'\n')
obFichier.write(codexe+'\n')
obFichier.close()
SUBEXE="/usr/bin/sbatch"
code_launch='%s %s ' %(SUBEXE,sub)
args   = shlex.split(code_launch)
print(args)
try :   subprocess.check_call(args)
except :
     print 'Launch %s failed' %sub
     sys.exit(1)
