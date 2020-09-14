#!/bin/ksh 
CONFIG="PSY4QV3R1"
DATE1="20200901"
DATE2="20200901"
typedata="profile"
typemod="pgn"
srcdata="GODAE"
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=${srcdata} --data=${typedata} --typemod=${typemod}
