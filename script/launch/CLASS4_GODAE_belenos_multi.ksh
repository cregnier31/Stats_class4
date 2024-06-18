#!/bin/ksh
#SBATCH -J CLASS4_GLO12
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12_GODAE_DRIFTER_150-job%j.e
#SBATCH -o CLASS4_GLO12_GODAE_DRIFTER_150-job%j.o
#SBATCH --ntasks-per-node=20
#SBATCH --time=5:00:00
HDF5_USE_FILE_LOCKING=False
orte_base_help_aggregate=0
module load nco
CONFIG="GLO12V5-150"
DATE1="20240103"
DATE2="20240430"
#DATE2="20240105"
typedata="profile"
typedata="SLA"
typedata="DRIFTER_filtr"
typedata="DRIFTER"
typemod="pgn"
case $typedata in
    SST|SLA|profile|aice)
        srcdata="GODAE"
        #options='-- all'
        options='-- best'
    ;;
    DRIFTER|DRIFTER_filtr)
        srcdata="CMEMS_013_048"
        options='--best --clim --bathy'
    ;;
    *)
    echo "$typedata not known"
    ;;
esac
typemod="pgn"
loglevel=6
DIR_BIN="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38/bin/"
${DIR_BIN}mpirun -np 20 ${DIR_BIN}python ../TEP_CLASS4_kdtree_multiproc.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} $options
