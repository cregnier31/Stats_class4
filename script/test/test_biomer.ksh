#!/bin/ksh
CONFIG="BIOMER4V2R1"
date1="20210201"
date2="20210201"
loglevel=2
typedata="chloro"
typemod="pgn"
srcdata="GLOBCOLOUR"
loglevel=2
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${date1} --date2=${date2} --src=${srcdata}\
            --data=${typedata} --typemod=${typemod} --loglevel=${loglevel} 
