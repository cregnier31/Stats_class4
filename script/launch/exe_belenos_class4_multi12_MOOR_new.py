#!/usr/bin/env python
#SBATCH -J TEST2
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 12
#SBATCH -e TEST_CODE_MAY_job%j.e
#SBATCH -o TEST_CODE_MAY_job%j.o
#SBATCH --ntasks-per-node=12
#SBATCH --time=05:30:00

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
old_obs = 'new'
date = 202206

# **************************** Environnement ***********************************
os.chdir(pbsworkdir)
EXE = os.path.join(pbsworkdir,'../exe_colloc_mooring_multi.py')
try : os.remove(os.path.join(pbsworkdir,"OK.flag"))
except : pass
dir_bin="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38_bis/bin/"
# **************************** Python launcher *********************************
nb_process=144
#os.system(dir_bin+"mpirun -np "+str(nb_process)+" "+dir_bin+"python %s --year=%s --month=%s --system=%s --tstp=%s" \
#        %(EXE, year, month, system, time_step))
#os.system(dir_bin+"python %s --year=%s --month=%s --system=%s --tstp=%s" \
#        %(EXE, year, month, system, time_step))
#
#os.system(dir_bin+"python %s %s %s %s %s" \
#        %(EXE, system, date, time_step, old_obs))
os.system(dir_bin+"mpirun -np "+str(nb_process)+" "+dir_bin+"python %s %s %s %s %s" \
        %(EXE, system, date, time_step, old_obs))
