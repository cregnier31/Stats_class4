#!/bin/ksh
day1="20160106"
day2="20160131"
cfgfile="${PWD}/environment_BIOMER4V1R2.cfg"
typedata="chloro"
echo $cfgfile
python ./exe_calcul_stats_CL4.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --datatype=$typedata

