#!/usr/bin/env python
#SBATCH -J TEST_MOOR
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 12
#SBATCH -e TEST_CODE_job%j.e
#SBATCH -o TEST_CODE_job%j.o
#SBATCH --ntasks-per-node=10
#SBATCH --time=02:30:00

import shlex,subprocess
import os,sys,getopt
import resource

# ********************** Set Stack unlimited **********************************

resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# ********************** Source environnement *********************************

pbsworkdir = "/home/ext/mr/smer/regnierc/SAVE/INSTALL/TEP_CLASS4_dev/script/launch/"
year = 2022
month = 5
time_step = "daily"
time_step = "hourly"
system = "PSY4V3R1"

# **************************** Environnement ***********************************
os.chdir(pbsworkdir)
EXE = os.path.join(pbsworkdir,'../exe_colloc_mooring_multiproc.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag")) 
except : pass
dir_bin="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38_bis/bin/"
# **************************** Python launcher *********************************
nb_process=120
#os.system(dir_bin+"mpirun -np "+str(nb_process)+" "+dir_bin+"python %s --year=%s --month=%s --system=%s --tstp=%s" \
#        %(EXE, year, month, system, time_step))
os.system(dir_bin+"python %s --year=%s --month=%s --system=%s --tstp=%s" \
        %(EXE, year, month, system, time_step))
