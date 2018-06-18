#!/bin/ksh
day1="20130501"
day2="20161031"
cfgfile="${PWD}/../environment_PSY4V2R2.cfg"
day1="20180501"
day2="20180531"
cfgfile="${PWD}/../environment_PSY4V3R1.cfg"
exp="PHYS"

echo $cfgfile
cd ..
python ./create_ProdQualStats.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --type=$exp 

