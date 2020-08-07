#!/bin/ksh
CONFIG="BIOMER4V2R1"
date1="20200701"
date2="20200702"
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${date1} --date2=${date2} --src=GLOBCOLOUR --data=chloro --typemod=pgn
