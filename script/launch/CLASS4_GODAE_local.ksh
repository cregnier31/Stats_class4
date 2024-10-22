#!/usr/bin/ksh
#SBATCH -J CLASS4_GLO12V5
#SBATCH -A cmems
#SBATCH -p normal256
#SBATCH -N 1
#SBATCH -e CLASS4_GLO12V5-150_DRIFTER_2024_job%j.e
#SBATCH -o CLASS4_GLO12V5-150_DRIFTER_2024_job%j.o
#SBATCH --ntasks-per-node=1
#SBATCH --time=06:00:00
module load nco
CONFIG="GREP"
DATE1="20110101"
DATE2="20221231"
DATE1="20100101"
DATE2="20221231"
DATE1="20220612"
DATE2="20220612"
DATE1="20190201"
DATE2="20190201"
DATE1="20200808"
DATE2="20200808"
DATE1="20200821"
DATE2="20200821"
DATE1="20150321"
DATE2="20150321"
#DATE1="20010627"
#DATE2="20010627"
#DATE2="19960305"
#DATE2="20240103"
#DATE2="20240105"
#typedata="profile"

typedata="aice"
typedata="DRIFTER"
#typedata="DRIFTER_filtr"
typedata="CORA5.2"
#typedata="SST"
#typedata="SLA"
#typedata="DRIFTER"
typemod="pgs"
dirlog="/home/cregnier/Gitlab/TEP_CLASS4_creation/script/log/"

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
    CORA5.2)
        srcdata="NC_CORIO"
        options='--best' # --clim'
    ;;
    *)
    echo "$typedata not known"
    exit 1
    ;;
esac
loglevel=1
DIR_BIN="/data/rd_exchange/qualif/anaconda3/envs/env_py311/bin/"
${DIR_BIN}python ../TEP_CLASS4_kdtree_optim.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} ${options} --dirlog=${dirlog}
