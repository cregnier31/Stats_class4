#!/bin/ksh
#SBATCH -J CLASS4_GLO12
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12_profile_multi_202401-2-job%j.e
#SBATCH -o CLASS4_GLO12_profile_multi_202401-2-job%j.o
#SBATCH --ntasks-per-node=20
#SBATCH --time=5:00:00
HDF5_USE_FILE_LOCKING=False
orte_base_help_aggregate=0
module load nco
CONFIG="GLO12V4"
DATE1="20240116"
DATE2="20240131"
DATE1="20240116"
DATE2="20240131"
#DATE1="20230901"
#DATE2="20230930"
#DATE2="20231031"
#DATE2="20231031"
#DATE2="20230905"
typedata="profile"
typemod="pgn"
srcdata="NC_CORIO"
loglevel=7
#which python
DIR_BIN="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38/bin/"
${DIR_BIN}mpirun -np 20 ${DIR_BIN}python ../TEP_CLASS4_kdtree_multiproc.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} --all
