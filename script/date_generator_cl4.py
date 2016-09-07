import sys

sys.path.append("/home/ext/mr/smer/regnierc/SAVE/python/module/")

from sytoolkit.sydate import SyDate
import re,subprocess,shlex

##DATEINI="20130161"
##DAYMAX="20141231"
##DATEINI="20131101"
##DAYMAX="20131231"
##DATEINI="20140401"
##DAYMAX="20140531"
##DATEINI="20130101"
DATEINI="20140101"
DAYMAX="20140331"
#DATEINI="20160616"
#DAYMAX="20160620"
#DATEINI="20130115"
#DAYMAX="20130118"
#DATEINI="20130511"
#DAYMAX="20130513"
dayvalmax=SyDate(DAYMAX)
dayvalmin=SyDate(DATEINI)
CODE="./Launch_class4_prolix_mono.py"
system="PSY4V3R1"
NBDATE="1"
DELTA="0"
SRC="GODAE"
DATA="AMSR"
#DATA="aice"
NB_PROC="12"
while dayvalmin <= dayvalmax : 
    print str(dayvalmin)
##  Launch class4
    code_launch= 'python %s %s %s %s %s %s %s %s ' %(CODE,system,dayvalmin,NBDATE,DELTA,SRC,DATA,NB_PROC)
    dayvalmin=dayvalmin.goforward(1)  
    args   = shlex.split(code_launch)
    print args
    try :   subprocess.check_call(args)
    except :
        print 'Launch class4 %s failed' %args


#while valeurj.__lt__(dayvalmax) :
#    print SyDate.__str__(valeurj)
#    dateval=SyDate.__str__(valeurj)
#    valeurj=valeurj.goforward(1)  

