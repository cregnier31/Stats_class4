#!/bin/sh
#SBATCH -J CLASS4_GLO12V4_NEW
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12V4_NEW_OPER_2025_job%j.e
#SBATCH -o CLASS4_GLO12V4_NEW_OPER_2025_job%j.o
#SBATCH --time=06:00:00
conda activate env_py311
DIR_BIN="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py311/bin/"
CONFIG="GLO12V4_NEW"
DATERUN=$(date -d "next wed" +%Y%m%d)
DATE1=20260101
DATE2=20260116
loglevel=2
typemod="pgn"
num_maxprocs=3
num_maxthreads=12
#typedata="SLA-L3"
#confname="../cfg/config_local.cfg"
#ulimit -s unlimited
##time ${DIR_BIN}class4-run --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
##        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --all 
#time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
#        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --all \
#        --np_max=${num_maxprocs} --np_threads=${num_maxthreads}
#echo "---------- SLA OK ------------"
#num_maxprocs=3
#num_maxthreads=12
#typedata="aice"
#confname="../cfg/config_local.cfg"
#time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
#        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --all \
#         --np_max=${num_maxprocs} --np_threads=${num_maxthreads}
#
#echo "---------- aice OK ------------"
typedata="profile_TS_DB"
confname="../cfg/config_local.cfg"
num_maxprocs=3
num_maxthreads=12
time ${DIR_BIN}class4-run --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --all #\
  #      --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

echo "---------- TS_DB OK ------------"

typedata="profile_PR_PF"
confname="../cfg/config_local.cfg"
num_maxprocs=3
num_maxthreads=12
time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --all \
        --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

echo "---------- PR_PF OK ------------"

#num_maxprocs=1
#num_maxthreads=12
#
#typemod="clim_curr"
#typedata="DRIFTER_filtr"
#time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
#        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --no-recombine \
#         --np_max=${num_maxprocs} --np_threads=${num_maxthreads}
##
#typemod="bathy"
#time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
#        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --no-recombine \
#        --np_max=${num_maxprocs} --np_threads=${num_maxthreads}
##
##typemod="smoc"
##time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE3} --date2=${DATE4} \
##        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --no-recombine \
##        --np_max=${num_maxprocs} --np_threads=${num_maxthreads}
##
#typemod="pgn"
#time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
#        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --all --cfg=${confname} \
#        --np_max=${num_maxprocs} --np_threads=${num_maxthreads}
#
#echo "---------- Currents filtr OK ------------"

typedata="profile_type1"
confname="../cfg/config_local.cfg"
num_maxprocs=3
num_maxthreads=12
time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --all \
        --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

echo "---------- PR type1 OK ------------"
exit 1
typedata="profile_type2"
confname="../cfg/config_local.cfg"
num_maxprocs=3
num_maxthreads=12
time ${DIR_BIN}class4-run-parall --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --cfg=${confname} --all \
        --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

echo "---------- PR type2 OK ------------"



