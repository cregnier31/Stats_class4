#!/usr/bin/env python
#SBATCH -J CLASS4_UV
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 12
#SBATCH -e CLASS4_UV_2022_06_job%j.e
#SBATCH -o CLASS4_UV_2022_06_job%j.o
#SBATCH --ntasks-per-node=20
#SBATCH --time=18:30:00

import shlex,subprocess
import os,sys,getopt
import resource

# ********************** Set Stack unlimited **********************************

resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# ********************** Source environnement *********************************

#pbsworkdir  = os.getenv('pbsworkdir')
#year  = os.getenv('year')
#month = os.getenv('month')
#system = os.getenv('system')
pbsworkdir = "/home/ext/mr/smer/regnierc/SAVE/INSTALL/TEP_CLASS4_dev/script/launch/"
year = 2022
month = 6
system = "PSY4V3R1"

# **************************** Environnement ***********************************
#os.environ["HDF5_USE_FILE_LOCKING"] = "FALSE"
os.chdir(pbsworkdir)
EXE = os.path.join(pbsworkdir,'../exe_colloc_drifter_multiprocess.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag"))
except : pass
dir_bin="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38_bis/bin/"

# **************************** Python launcher *********************************
nb_procs=240
#nb_procs=400
print("Launch system")
os.system(dir_bin+"mpirun -np "+str(nb_procs)+" "+dir_bin+"python %s --year=%s --month=%s --system=%s" \
        %(EXE,year,month,system))
