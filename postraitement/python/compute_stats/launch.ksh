#!/bin/ksh
day1="20160101"
day2="20160102"
cfgfile="${PWD}/environment_BIOMER4V1R2.cfg"
typedata="chloro"
echo $cfgfile
python ./exe_Lecture_class4.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --type=$typedata

