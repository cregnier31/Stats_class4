#!/bin/sh
CONFIG="GLO12V4"
DATERUN=$(date -d "next wed" +%Y%m%d)
DATEJ14=$(date -d "${DATERUN} -14 days" +%Y%m%d)
DATEJ10=$(date -d "${DATERUN} -10 days" +%Y%m%d)
DATEJ8=$(date -d "${DATERUN} -8 days" +%Y%m%d)
DATEJ21=$(date -d "${DATERUN} -21 days" +%Y%m%d)
echo $DATERUN $DATEJ14 $DATEJ8
## Define DATEEUN J-14
## DEfine DATERUN J-8
DATE1=$DATEJ14
DATE2=$DATEJ8
DATE3=$DATEJ21
DATE4=$DATEJ10
#DATE1="20250902"
#DATE2="20250909"
loglevel=2
num_maxprocs=7
num_maxthreads=12
DIR_SRC="/home/smer/regnierc/code/TEP_CLASS4_creation/"
DIR_BIN="/home/smer/regnierc/mambaforge/envs/env_py311/bin/"
typemod="clim_curr"
typedata="DRIFTER_filtr"
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

typemod="pgn"
typedata="all"
time ${DIR_BIN}python ${DIR_SRC}src/tep_class4/cli/class4_parallel_leadtime_recomb.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --typemod=${typemod} --loglevel=${loglevel} --data=${typedata} --all --np_max=${num_maxprocs} --np_threads=${num_maxthreads}

