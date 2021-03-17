#!/usr/bin/env python
#SBATCH -J TEP_CLASS4
#SBATCH -p multi
#SBATCH -N 4
#SBATCH -e TEP_CLASS4_job%j.e
#SBATCH -o TEP_CLASS4_job%j.o
#SBATCH -q qosmulti
#SBATCH --exclusive
#SBATCH --ntasks-per-node=1
#SBATCH --time=06:00:00

import shlex,subprocess
import os,sys,getopt
import resource

# ********************** Set Stack unlimited **********************************

resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# ********************** Source environnement *********************************

pbsworkdir  = os.getenv('pbsworkdir')
day1  = os.getenv('day1')
day2 = os.getenv('day2')
cfg = os.getenv('cfg')
source  = os.getenv('source')
typedata = os.getenv('typedata')
mode = os.getenv('mode')


# **************************** Environnement ***********************************

os.environ["HDF5_USE_FILE_LOCKING"] = "FALSE"
os.chdir(pbsworkdir)
EXE = os.path.join(pbsworkdir,'../TEP_CLASS4_kdtree_multiproc.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag"))
except : pass
dir_bin="/data/rd_exchange2/qualif/anaconda/envs/env_py38/bin/"


# **************************** Python launcher *********************************

os.system(dir_bin+"mpirun -np 4 "+dir_bin+"python %s --config=%s --date1=%s --date2=%s --src=%s --data=%s --typemod=%s" \
        %(EXE, cfg, day1, day2, source, typedata, mode))
