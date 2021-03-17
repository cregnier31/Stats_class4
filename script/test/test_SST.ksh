#!/bin/ksh 
CONFIG="PSY4QV3R1"
DATE1="20210203"
DATE2="20210207"
DATE1="20210215"
DATE2="20210216"
DATE1="20210303"
DATE2="20210309"
typedata="SST"
typemod="pgn"
srcdata="GODAE"
loglevel=2
which python
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
          	--src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
