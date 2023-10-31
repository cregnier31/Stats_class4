#!/bin/ksh 
CONFIG="GLO12V4"
DATE1="20230412"
DATE2="20230418"
typedata="SLA"
typemod="pgn"
srcdata="GODAE"
loglevel=1
dir_script="/home/smer/regnierc/code/test/TEP_CLASS4_dev/script/"
python ${dir_script}TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        	--src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
