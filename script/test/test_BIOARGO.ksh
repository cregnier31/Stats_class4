#!/bin/ksh
CONFIG="BIOMER4V2R1"
date1="20170929"
date2="20170929"
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${date1} --date2=${date2} --src=BIOARGO --data=nitrate --typemod=pgn
