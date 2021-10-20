#!/bin/ksh 
CONFIG="PSY4QV3R1"
DATE1="20210210"
DATE2="20210210"
DATE1="20210414"
DATE2="20210420"
typedata="aice"
typemod="pgn"
srcdata="GODAE"
python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=${srcdata} --data=${typedata} --typemod=${typemod}
