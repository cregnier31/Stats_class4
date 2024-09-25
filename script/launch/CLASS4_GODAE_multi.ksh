#!/usr/bin/ksh
#SBATCH -J CLASS4_PGS_GREP
#SBATCH -p multi
#SBATCH -N 4
#SBATCH -q qosmulti
#SBATCH --exclusive
#SBATCH -e /kara/data1/cregnier/log/GREP_PGS_CLASS4_2018_job%j.e
#SBATCH -o /kara/data1/cregnier/log/GREP_PGS_CLASS4_2018_job%j.o
#SBATCH --ntasks-per-node=10
#SBATCH --time=06:00:00
module load nco
CONFIG="GREP"
DATE1="20180101"
DATE2="20181231"
typedata="aice"
typedata="DRIFTER"
typedata="CORA5.2"
#typedata="SST"
#typedata="SLA"
#typedata="DRIFTER"
typemod="pgs"
dirlog="/kara/data1/cregnier/log/"
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
loglevel=7
DIR_BIN="/data/rd_exchange/qualif/anaconda3/envs/env_py311/bin/"
${DIR_BIN}mpirun -np 40 ${DIR_BIN}python ../TEP_CLASS4_kdtree_multiproc.py \
                 --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} \
                 --src=${srcdata} --data=${typedata} --typemod=${typemod} \
                 --loglevel=${loglevel} ${options} --dirlog=${dirlog}
