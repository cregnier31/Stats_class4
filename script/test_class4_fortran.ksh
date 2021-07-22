#!/bin/ksh
dir_bin=/data/rd_exchange/qualif/miniconda3/envs/env_py38/bin/
nb_procs=10
loglevel=1
date1="20200101"
date2="20201231"
daymax="20170101"
config="PSY4V3R1"
#config="GLORYS12V1-light"
typemod="pgn"
#typemod="allege"
src_data="CORA5.2"
#src_data="CORIO_CMEMS"

${dir_bin}python ./TEP_CLASS4_fortran.py --typemod=${typemod} --config=${config} \
    --date1=${date1} --date2=${date2} --src=${src_data} --data=profile --nbproc=${nb_procs}\
    --loglevel=${loglevel} --daymax=${daymax}
