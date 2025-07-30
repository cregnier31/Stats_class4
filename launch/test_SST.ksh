ONFIG="GLO12V4"
DATE1="20240701"
DATE2="20240701"
typedata="SST"
typemod="pgn"
srcdata="GODAE"
loglevel=1
python ../src/tep_class4/cli/class4.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}

