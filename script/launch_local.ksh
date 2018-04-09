#!/bin/ksh 
CONFIG="GLORYS12V1"
DATE1=20070624
DATE2=20070630
NB_PROC=1
python ./TEP_CLASS4_multiprocess_local.py --typemod=allege --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=CORA5 --data=profile --nbproc=${NB_PROC}

