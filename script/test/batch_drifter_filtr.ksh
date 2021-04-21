#!/bin/ksh 
#SBATCH -J CLASS4_UV_filtr
#SBATCH -A CMEMS
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_UV_filtr_job%j.e
#SBATCH -o CLASS4_UV_filtr_job%j.o
#SBATCH --time=00:30:00
CONFIG="PSY4QV3R1"
typemod="pgn"
srcdata="CMEMS_013_048"
typedata="DRIFTER_filtr"
#typedata="DRIFTER"
typemod="pgn"
srcdata="CMEMS_013_048"
loglevel=1
DATE1="20200101"
DATE2="20200108"
dir_bin="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38/bin/"

python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=${srcdata} \
	--data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
