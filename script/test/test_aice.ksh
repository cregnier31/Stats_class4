#!/bin/ksh 
cd ..
CONFIG="PSY4QV3R1"
DATERUN="20200710"
python ./TEP_CLASS4_kdtree.py --config=${CONFIG} --daterun=${DATERUN} --nbdate=1 --delta=0 --src=GODAE --data=aice --typemod=pgn
