#!/bin/ksh
day1="20200701"
day2="20200702"

## Test different configurations
config="PSY4V3R1"
#config="BIOMER4V2"
#config="PSY4V2R2"
#config="HYCOM_RTOFS"
#config="GIOPS"
#config="FOAM"
cfgfile=./cfg/environment_${config}.cfg
dir_bin="/data/rd_exchange2/qualif/anaconda/envs/env_py38/bin/"
if [ ${config} = "BIOMER4V2" -o ${config} = "BIOMER4V1" ] ; then
    typedata="BIO"
else
    typedata="PHYS"
fi

## Timeseries
daily_off="on"
bilan="off"
fmt_ascii="off"
debug="1"
fmt_mask="basin"
${dir_bin}python ./exe_compute_stats_CMEMS_areas_multiprocess.py --day1=${day1} --day2=${day2} --cfg=${cfgfile} \
    --type=${typedata} --fmt_mask=${fmt_mask} --bilan=${bilan} --fmt_ascii=${fmt_ascii} --daily_off=${daily_off} \
    --debug=${debug}
exit
## statistics 2D
daily_off="off"
bilan="on"
debug="1"
fmt_ascii="off"
# 2deg bins
fmt_mask="bins2d"
${dir_bin}python ./exe_compute_stats_CMEMS_areas_multiprocess.py --day1=${day1} --day2=${day2} --cfg=${cfgfile} \
    --type=${typedata} --fmt_mask=${fmt_mask} --bilan=${bilan} --fmt_ascii=${fmt_ascii} --daily_off=${daily_off} --debug=${debug}
# CMEMS area
fmt_mask="basin"
${dir_bin}python ./exe_compute_stats_CMEMS_areas_multiprocess.py --day1=${day1} --day2=${day2} --cfg=${cfgfile} \
    --type=${typedata} --fmt_mask=${fmt_mask} --bilan=${bilan} --fmt_ascii=${fmt_ascii} --daily_off=${daily_off} --debug=${debug}


## Percentiles
daily_off="on"
bilan="off"
fmt_ascii="off"
debug="1"
fmt_mask="basin"
nblevel=50
percent="on"
${dir_bin}python ./exe_compute_stats_CMEMS_areas_multiprocess.py --day1=${day1} --day2=${day2} --cfg=${cfgfile} \
    --type=${typedata} --fmt_mask=${fmt_mask} --bilan=${bilan} --fmt_ascii=${fmt_ascii} --daily_off=${daily_off} \
   --percent=${percent} --nblevel=${nblevel} --debug=${debug}

