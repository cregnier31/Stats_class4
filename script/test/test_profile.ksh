#!/bin/ksh 
CONFIG="PSY4QV3R1"
DATE1="20210203"
DATE2="20210131"
DATE1="20210330"
DATE2="20210330"
typedata="profile"
typemod="pgn"
srcdata="GODAE"
loglevel=1
#dask=True
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=${srcdata} \
	--data=${typedata} --typemod=${typemod} --loglevel=${loglevel} -d
