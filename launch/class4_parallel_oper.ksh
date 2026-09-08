#!/bin/sh
CONFIG="GLO12V4"
DATERUN=$(date -d "next wed" +%Y%m%d)
PREV_TUES=$(date -d "last tuesday -7 days" +%Y%m%d)
DATEINI=$(date -d "${PREV_TUES} -7 days" +%Y%m%d)
DATEINI_DRIFT=$(date -d "${PREV_TUES} -14 days" +%Y%m%d)
#DATEJ14=$(date -d "${DATERUN} -15 days" +%Y%m%d)
DATE4=$PREV_TUES
DATE3=$DATEINI_DRIFT
loglevel=2
num_maxprocs=7
num_maxthreads=12
DIR_SRC="/home/smer/regnierc/code/TEP_CLASS4_creation/"
DIR_BIN="/home/smer/regnierc/mambaforge/envs/env_py311/bin/"
typemod="clim_curr"
typedata="DRIFTER_filtr"
echo $DATE3 $DATE4
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --np_max=${num_maxprocs} --np_threads=${num_maxthreads} --no-recombine 
typemod="bathy"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --np_max=${num_maxprocs} --np_threads=${num_maxthreads} --no-recombine 
typemod="smoc"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --np_max=${num_maxprocs} --np_threads=${num_maxthreads} --no-recombine 
typemod="pgn"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --all --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

typedata="DRIFTER"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --np_max=${num_maxprocs} --np_threads=${num_maxthreads} --no-recombine 
typemod="bathy"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --np_max=${num_maxprocs} --np_threads=${num_maxthreads} --no-recombine 
typemod="smoc"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --np_max=${num_maxprocs} --np_threads=${num_maxthreads} --no-recombine 
typemod="pgn"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE3} --date2=${DATE4}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --all --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

DATE1=$DATEINI
DATE2=$PREV_TUES
typemod="pgn"
typedata="all"
echo $DATE1 $DATE2
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --all --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

