# Python launcher for CLASS4 post treatment
import os, sys
PATHLIB= os.path.dirname(os.path.realpath(__file__))
sys.path.append('../../../../modules/')
from utils import loader, create_launcher_multi, launch_sbatch

tab_conf = loader(sys.argv[1:])
if tab_conf['bilan'] ==  "on":
    print ('Launch bilan')
    launcher = create_launcher_multi(tab_conf, nbtasks='1', timecounter='06:00:00', nb_procs='4')
elif tab_conf['fmt_mask'] == None:
    print ('Inside launcher')
    launcher = create_launcher_multi(tab_conf, nbtasks='30', timecounter='06:00:00', nb_procs='2')
else:
    launcher = create_launcher_multi(tab_conf)
print (launcher)
launch_sbatch(launcher)
