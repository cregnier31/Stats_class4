#!/bin/ksh
CONFIG="GLO12V4"
DATE1="20170212"
DATE2="20170213"
typedata="SST"
typemod="pgn"
srcdata="GODAE"
loglevel=1
which python
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
