#!/bin/ksh 
CONFIG="PSY4V3R1"
DATE1="20210422"
DATE2="20210422"
typedata="SIT-legos"
typemod="pgn"
srcdata="LEGOS"
loglevel=1
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
	--src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
