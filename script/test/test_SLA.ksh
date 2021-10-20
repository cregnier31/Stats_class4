#!/bin/ksh 
CONFIG="PSY4QV3R1"
DATE1="20210616"
DATE2="20210630"
typedata="SLA"
typemod="pgn"
srcdata="GODAE"
loglevel=1
which python
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        	--src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
