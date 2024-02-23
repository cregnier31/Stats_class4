#!/usr/bin/env python
#SBATCH -J CLASS2_MOOR
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 12
#SBATCH --ntasks-per-node=2
#SBATCH -e CLASS2_MOOR_PSY4_job%j.e
#SBATCH -o CLASS2_MOOR_PSY4_job%j.o
#SBATCH --time=20:00:00

import shlex,subprocess
import os,sys,getopt
import resource

# ********************** Set Stack unlimited **********************************
# commentaire SBATCH --ntasks-per-node=3
resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))


# ********************** Source environnement *********************************

pbsworkdir = "/home/ext/mr/smer/regnierc/SAVE/INSTALL/TEP_CLASS4/script/launch/"
date = 202205
system = 'PSY4V3R1'
old_obs = 'old'
time_step = 'daily'

# **************************** Environnement ***********************************
os.chdir(pbsworkdir)
EXE = os.path.join(pbsworkdir,'../exe_colloc_mooring_multi.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag"))
except : pass
dir_bin="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38_bis/bin/"

# **************************** Python launcher *********************************
nb_process=24
os.system(dir_bin+"mpirun -np "+str(nb_process)+" "+dir_bin+"python %s %s %s %s %s" \
        %(EXE, system, date, time_step, old_obs))
