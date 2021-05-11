#!/bin/ksh
CONFIG="000GLORYS4V2"
DATE1="20110422"
DATE2="20110422"
typedata="SIT-legos"
typedata="SNOW-legos"
typemod="pgn"
srcdata="LEGOS"
loglevel=1
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
    --src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
