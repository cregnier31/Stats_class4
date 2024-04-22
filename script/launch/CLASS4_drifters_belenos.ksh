#!/bin/ksh
#SBATCH -J CLASS4_GLO12V5
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12V5_drifters_corr_2024_job%j.e
#SBATCH -o CLASS4_GLO12V5_drifters_corr_2024_job%j.o
#SBATCH --ntasks-per-node=1
#SBATCH --time=06:00:00
module load nco
CONFIG="GLO12V5"
DATE1="20240103"
DATE2="20240305"
typedata="DRIFTER_filtr"
#typedata="DRIFTER"
typemod="pgn"
srcdata="CMEMS_013_048"
loglevel=1
which python
DIR_BIN="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38/bin/"
${DIR_BIN}python ../TEP_CLASS4_kdtree_new.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} --best
