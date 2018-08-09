#!/usr/bin/env python
#PBS -N CLASS4
#SBATCH -p multi
#SBATCH -N 4
#SBATCH -q qosmulti
#SBATCH --exclusive
#SBATCH --ntasks-per-node=4
#SBATCH --time=01:00:00

#---------------------------------------------------
import shlex,subprocess
import os,sys,getopt
import resource

## Set Stack unlimited
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))
## Source environnement 
#os.system("source activate env_py35")
pbsworkdir  = os.getenv('pbsworkdir')
cl_dateMinZone = os.getenv('day1')
cl_dateMaxZone = os.getenv('day2')
_DBFILE_ = os.getenv('cfg')
datatype = os.getenv('type')
_NPROCS_=32
#_NPROCS_ = 16

#~~~~ Environment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
os.chdir(pbsworkdir)

EXE = os.path.join(pbsworkdir,'../exe_Lecture_class4_multiprocess.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag")) 
except : pass
dir_bin="/kara/data1/cregnier/env_kara_py27/bin/"
print ("Debut mpirun")
os.system(dir_bin+"mpirun -np 32 "+dir_bin+"ipython --verbose_crash=True -- %s --day1=%s --day2=%s --cfg=%s --type=%s" %(EXE,cl_dateMinZone,cl_dateMaxZone,_DBFILE_,datatype))
open(os.path.join(pbsworkdir,"OK.flag"), "a") 
