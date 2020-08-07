#!/bin/ksh
YEAR=2019
MONTH=3
SYSTEM="PSY4V3R1"
dir_bin="/home/cszczypta/anaconda3/envs/env_py27/bin/"
${dir_bin}python ../exe_colloc_drifter_multiprocess.py --year=${YEAR} --month=${MONTH} --system=${SYSTEM}
