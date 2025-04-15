#!/bin/ksh
day1="20190901"
day2="20190930"
cfg="BIOMER4V1R2"
source="GLOBCOLOUR"
typedata="chloro"
mode="pgn"

cd ../
python TEP_CLASS4_kdtree.py --config=$cfg --date1=$day1 --date2=$day2 --src=$source --data=$typedata --typemod=$mode
