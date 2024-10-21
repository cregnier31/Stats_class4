#!/usr/bin/ksh
#SBATCH -J CLASS4_GLO12V5
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_AI_2024_profile_202406_job%j.e
#SBATCH -o CLASS4_AI_2024_profile_202406_job%j.o
#SBATCH --ntasks-per-node=1
#SBATCH --time=06:00:00
module load nco
CONFIG="XIhe-local"
CONFIG="GLONET"
DATE1="20240104"
DATE2="20240713"
#DATE2="20240104"
#typedata="DRIFTER"
#typedata="DRIFTER_filtr"
typedata="SST"
typedata="SLA"
typedata="profile"
#typedata="profile"
typemod="pgs_ai"
dirlog="/home/cregnier/Gitlab/TEP_CLASS4_creation/script/log/"

#srcdata="CMEMS_013_048"
case $typedata in
    SST|SLA|profile|aice)
        srcdata="GODAE"
        #options='-- all'
        #options='--best'
        options='--fcst'
    ;;
    DRIFTER|DRIFTER_filtr)
        srcdata="CMEMS_013_048"
        #options='--best --clim --bathy'
        options='--SMOC --best --clim --bathy --stokes --tides'
    ;;
    CORA5.2)
        srcdata="NC_CORIO"
        options='--best' # --clim'
    ;;
    *)
    echo "$typedata not known"
    exit 1
    ;;
esac
loglevel=2
#DIR_BIN="/data/rd_exchange/qualif/anaconda3/envs/env_py311/bin/"
DIR_BIN="/home/ext/mr/smer/regnierc/anaconda3/envs/env_py38/bin/"
${DIR_BIN}python ../TEP_CLASS4_kdtree_new.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} ${options} --dirlog=${dirlog}
