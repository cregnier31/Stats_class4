#!/bin/ksh
module load nco 
/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script/TEP_CLASS4_aice_test.py --config PSY4QV3R1 --daterun=20161026 --nbdate=1 --delta=0 --src=GODAE --data=aice --typemod=pgn
#/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script/TEP_CLASS4_aice.py --config PSY4QV3R1 --daterun=20161109 --nbdate=1 --delta=0 --src=GODAE --data=aice --typemod=pgn
