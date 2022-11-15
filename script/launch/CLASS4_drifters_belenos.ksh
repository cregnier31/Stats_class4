#!/bin/ksh
#SBATCH -J CLASS4_GLO12
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12_drifters_2019_job%j.e
#SBATCH -o CLASS4_GLO12_drifters_2019_job%j.o
#SBATCH --ntasks-per-node=1
#SBATCH --time=04:00:00
module load nco
CONFIG="GLO12V4"
DATE1="20200101"
DATE2="20211231"
typedata="DRIFTER_filtr"
typemod="pgn"
srcdata="CMEMS_013_048"
loglevel=1
which python
DIR_BIN="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38_bis/bin/"
${DIR_BIN}python ../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
        --src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
