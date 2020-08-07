#!/usr/bin/env python
#SBATCH -J CLASS4_UV
#SBATCH -p multi12
#SBATCH -N 12
#SBATCH -e CLASS4_UV_job%j.e
#SBATCH -o CLASS4_UV_job%j.o
#SBATCH -q qosmulti12
#SBATCH --exclusive
#SBATCH --ntasks-per-node=25
#SBATCH --time=05:00:00

import shlex,subprocess
import os,sys,getopt
import resource

# ********************** Set Stack unlimited **********************************

resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# ********************** Source environnement *********************************

pbsworkdir  = os.getenv('pbsworkdir')
year  = os.getenv('year')
month = os.getenv('month')
system = os.getenv('system')


# **************************** Environnement ***********************************
os.environ["HDF5_USE_FILE_LOCKING"] = "FALSE"
os.chdir(pbsworkdir)
EXE = os.path.join(pbsworkdir,'../exe_colloc_drifter_multiprocess.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag"))
except : pass
dir_bin="/home/cszczypta/anaconda3/envs/env_py27/bin/"


# **************************** Python launcher *********************************

os.system(dir_bin+"mpirun -np 300 "+dir_bin+"python %s --year=%s --month=%s --system=%s" \
        %(EXE,year,month,system))
