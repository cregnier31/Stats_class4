#!/bin/bash

CONFIG="000GLORYS4V2"
typemod="2ease"
typemod="pgn"
srcdata="LEGOS"
loglevel=2

#############################################################################
echo "######################################################################"
echo "On s'occupe de la climatologie KaKu."
echo "Colocalisation de la neige climato snow_depth_clim."
#############################################################################

#typedata="KaKuYearSH"
typedata="SNOW-legos"
rep_out1="/data/rd_exchange/cregnier/tmp/CLASS4/"
#dir_data='/data/rd_exchange/cregnier/Obs/SH/C2_esaD/SAR/'
dir_data='/homelocal-px/px-181/achenal/Projection_runs_7xx/'
for rep in `ls -d ${dir_data}*`; do
    liste_day=`ls ${rep}* | cut -f9 -d'_' | cut -c1-8 | uniq`
    cyclenum=`echo $rep | cut -f9 -d '/'`
    rep_out="${rep_out1}${cyclenum}"
    mkdir -p $rep_out
    echo $rep_out
    for DATE1 in $liste_day; do
         #python /home/cregnier/Gitlab/TEP_CLASS4/script/TEP_CLASS4_kdtree.py --config=${CONFIG}\
         /data/rd_exchange/qualif/anaconda3/envs/env_py38/bin/python /home/cregnier/Gitlab/TEP_CLASS4/script/TEP_CLASS4_kdtree.py --config=${CONFIG}\
                    --date1=${DATE1} --date2=${DATE1} --src=${srcdata} --data=${typedata} \
                    --typemod=${typemod} --loglevel=${loglevel} --dirinput=${rep} --diroutput=${rep_out}
    done
    echo "---------------------------------------"
    echo "Change cycle  ${rep}"
    echo "---------------------------------------"
done
