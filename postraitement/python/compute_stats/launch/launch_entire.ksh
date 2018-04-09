#!/bin/ksh
day1="20150107"
day2="20180131"
cfgfile="${PWD}/environment_BIOMER4.cfg"
typedata="chloro"
typedata2="CHL"
exp="BIO"

echo $cfgfile

#python ./exe_Lecture_class4_log10.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --type=$typedata

python ./exe_calcul_stats_CL4_new.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --datatype=$typedata2

python ./create_ProdQualStats.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --type=$exp 

#python ./valid_file_nc_new.py
