# Python launcher for CLASS4 post treatment
import os, sys
PATHLIB= os.path.dirname(os.path.realpath(__file__))
sys.path.append('./../modules/')
from utils import loader, create_launcher_multi, launch_sbatch
from loader_post import input_params, read_input_files
from Logger import Logger

level = 2
log = Logger("CLASS4 Statistics").run(level)
#tab_conf, log = input_params(sys.argv[1:], log)
tab_conf = loader(sys.argv[1:])
if tab_conf['bilan'] ==  "on":
    print ('Launch bilan')
    if tab_conf['typemod'] == 'PHYS':
        nbtasks = '2'
        nb_procs = '4'
    elif tab_conf['typemod'] == 'BIO':
        nbtasks = '1'
        nb_procs = '4'
    launcher = create_launcher_multi(tab_conf, nbtasks=nbtasks, timecounter='05:00:00', nb_procs=nb_procs)
else:
    if tab_conf['percent'] == None:
        print ('Launch timeserie')
        if tab_conf['typemod'] == 'PHYS':
            nbtasks = '30'
            nb_procs = '2'
        elif tab_conf['typemod'] == 'BIO':
            nbtasks = '5'
            nb_procs = '4'
        launcher = create_launcher_multi(tab_conf, nbtasks=nbtasks, timecounter='06:00:00', nb_procs=nb_procs)
    else:
        launcher = create_launcher_multi(tab_conf)

launch_sbatch(launcher)
