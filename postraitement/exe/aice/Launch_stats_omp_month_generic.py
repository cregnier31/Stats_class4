#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
import os,sys,string,shutil,glob,re
import subprocess,shlex
PATHLIB = os.path.dirname(os.path.realpath(__file__))
sys.path.append("../../../modules/")
from utilities import load_db
from glob import glob

#===============================
# Test sur le nombre d'arguments
# ===============================

if len(sys.argv) != 7:
    print('Usage: ./Launch_stats_omp.py <YEAR> <MONTH> <model> <zone> <leadtype> <machine>') 
    print(f'{len(sys.argv)=}')
    print(sys.argv)
    sys.exit(1)
else :
  YEAR=sys.argv[1]
  MONTH=sys.argv[2]
  model=sys.argv[3]
  zone=sys.argv[4]
  leadtype=sys.argv[5]
  machine=sys.argv[6]

if int(MONTH) < 10 :
    MONTH="0"+MONTH
else:
    MONTH=MONTH
cl_date=str(YEAR)+"_"+str(MONTH)
_DBFILE_ = PATHLIB + '/cfg/' + model + '.cfg'
print(_DBFILE_)
db = load_db(_DBFILE_)
DIRDATA = db.get('PATH', 'DIRDATA')
cl_path = db.get('PATH', 'cl_path')
cl_dirmask = db.get('PATH', 'cl_dirmask')
rl_seuil= float(db.get('PATH', 'rl_seuil'))
rl_seuil2 =  float(db.get('PATH', 'rl_seuil2'))
il_echeances =  int(db.get('PATH', 'il_echeances'))
BIN_DIR = PATHLIB + "/../../../bin/"
#exe = BIN_DIR+"Compute_seaice_stats_"+zone+"_"+machine+"_leadtime.exe"
exe = BIN_DIR+"Compute_seaice_stats_"+zone+"_"+machine+"_leadtime_best.exe"
dir_log = PATHLIB + "/log/"
nml = PATHLIB + "/../../../NAMELIST/namelist_aice_"+zone+"_"+model+"_"+YEAR+MONTH+".nml"
sub = PATHLIB + "/../../../sub/launch_stats_"+zone+"_"+YEAR+MONTH+"_"+model+"_omp.pbs"
list_file=[]
for file in sorted(glob(DIRDATA+"/class4_"+YEAR+MONTH+"*"+model+"*aice.nc")):
    list_file.append(file)
if not list_file : 
    print("None in the list")
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
     print('Launch %s failed' %sub)
     sys.exit(1)
