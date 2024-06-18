#!/bin/ksh
#SBATCH -J CLASS4_GLO12V5
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12V5-150_DRIFTER_2024_job%j.e
#SBATCH -o CLASS4_GLO12V5-150_DRIFTER_2024_job%j.o
#SBATCH --ntasks-per-node=1
#SBATCH --time=06:00:00
module load nco
CONFIG="GLO12V5-150"
DATE1="20240103"
DATE2="20240430"
#DATE2="20240103"
#DATE2="20240105"
#typedata="profile"

typedata="aice"
typedata="DRIFTER"
#typedata="DRIFTER_filtr"
#typedata="profile"
#typedata="SST"
#typedata="SLA"
#typedata="DRIFTER"
typemod="pgn"

#srcdata="CMEMS_013_048"
case $typedata in
    SST|SLA|profile|aice)
        srcdata="GODAE"
        #options='-- all'
        options='--best'
    ;;
    DRIFTER|DRIFTER_filtr)
        srcdata="CMEMS_013_048"
        #options='--best --clim --bathy'
        options='--SMOC --best --clim --bathy --stokes --tides'
    ;;
    *)
    echo "$typedata not known"
    ;;
esac
#typedata="aice"
#typedata="DRIFTER"
typemod="pgn"
#srcdata="GODAE"
loglevel=2
which python
DIR_BIN="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38/bin/"
${DIR_BIN}python ../TEP_CLASS4_kdtree_new.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} ${options}
