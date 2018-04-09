from math import *
import numpy as np

nb_proc=10
nb_pts=15
##x=np.arange(nb_pts)
##print np.split(x,nb_proc)
##sys.exit(1)
if nb_pts <=  nb_proc : 
    nb_process=nb_pts
    splitLen=1
else :
    print "dans le else"
    nb_process=nb_proc
    splitLen=int(ceil(nb_pts/nb_process))
print "longueur %i" %(splitLen)
cpt=1
ind=0
for lines in range(0,nb_pts,splitLen):
    # First, get the list slice
    print lines,lines+splitLen
    print "Split %s ok"%(cpt)
    print "lines cpt %i %i "%(lines,cpt)
    if cpt == nb_proc_2 :

    cpt += 1
