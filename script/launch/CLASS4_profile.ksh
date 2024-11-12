#!/bin/ksh
#SBATCH -J CLASS4_GLO12
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12_profile_202310_job%j.e
#SBATCH -o CLASS4_GLO12_profile_202310_job%j.o
#SBATCH --ntasks-per-node=1
#SBATCH --time=06:00:00
module load nco
CONFIG="GLO12V4"
DATE1="20240902"
#DATE2="20230930"
DATE2="20240909"
#DATE2="20240901"
typedata="profile"
typemod="pgn"
srcdata="NC_CORIO"
loglevel=2
DIR_BIN="/home/smer/regnierc/anaconda3/envs/env_py310/bin/"
${DIR_BIN}python ../TEP_CLASS4_kdtree_optim.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} --best --fcst --pers
