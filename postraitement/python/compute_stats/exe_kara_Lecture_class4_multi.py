#!/usr/bin/env python
#SBATCH -J CLASS4
#SBATCH -p multi
#SBATCH -N 4
#SBATCH -e CLASS4_job%j.e
#SBATCH -o CLASS4_job%j.o
#SBATCH -q qosmulti
#SBATCH --exclusive
#SBATCH --ntasks-per-node=4
#SBATCH --time=06:00:00

import shlex,subprocess
import os,sys,getopt
import resource

# ********************** Set Stack unlimited **********************************

resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# ********************** Source environnement *********************************

pbsworkdir  = os.getenv('pbsworkdir')
cl_dateMinZone = os.getenv('day1')
cl_dateMaxZone = os.getenv('day2')
datatype = os.getenv('type')
_DBFILE_ = os.getenv('cfg')
fmt_mask = os.getenv('fmt_mask')
bilan = os.getenv('bilan')
fmt_ascii = os.getenv('fmt_ascii')
daily_off = os.getenv('daily_off')


# **************************** Environnement ***********************************

os.chdir(pbsworkdir)
EXE = os.path.join(pbsworkdir,'../exe_compute_stats_CMEMS_areas_multiprocess.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag")) 
except : pass
#dir_bin="/home/cszczypta/anaconda3/envs/env_py27/bin/"
#dir_bin="/kara/data1/cregnier/env_kara_py27/bin/" 
#dir_bin="/homelocal-px/px-116/sauvegarde/cregnier/Program_files/miniconda2_kara/bin/" 

# **************************** Python launcher *********************************

if fmt_mask == None:
    os.system(dir_bin+"mpirun -np 160 "+dir_bin+"python %s --day1=%s --day2=%s --cfg=%s --type=%s" \
              %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_,datatype))
elif bilan == None:
    os.system(dir_bin+"mpirun -np 160 "+dir_bin+"python %s --day1=%s --day2=%s --cfg=%s --type=%s --fmt_mask=%s" \
              %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_,datatype, fmt_mask))
elif fmt_ascii == None:
    os.system(dir_bin+"mpirun -np 160 "+dir_bin+"python %s --day1=%s --day2=%s --cfg=%s --type=%s --fmt_mask=%s --bilan=%s" \
              %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_,datatype, fmt_mask, bilan))
elif daily_off == None:
    os.system(dir_bin+"mpirun -np 160 "+dir_bin+"python %s --day1=%s --day2=%s --cfg=%s --type=%s --fmt_mask=%s --bilan=%s --fmt_ascii=%s" \
              %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_,datatype, fmt_mask, bilan, fmt_ascii))
else:
    os.system(dir_bin+"mpirun -np 160 "+dir_bin+"python %s --day1=%s --day2=%s --cfg=%s --type=%s --fmt_mask=%s --bilan=%s --fmt_ascii=%s --daily_off=%s" \
              %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_,datatype, fmt_mask, bilan, fmt_ascii, daily_off))

