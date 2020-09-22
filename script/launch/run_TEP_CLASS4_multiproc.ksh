#!/bin/ksh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   >Brief   : Script general de lancement de TEP_CLASS4 pour collocaliser
#              les donnees de physique et de BIO et alimenter le site
#              CMEMS
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}

. ${PROGDIR}/../../postraitement/utils/myfunctions.ksh

day1=$1
day2=$2
cfg=$3
source=$4
typedata=$5
mode=$6

usage ()
{
    echo " "
    echo "*********** Incorrect number of Arguments ************ "
    echo " "
    echo "             --> 6 arguments required <-- "
    echo "       Value1 = Beginning day - fmt : YYYYMMDD"
    echo "          Value2 = End day  - fmt : YYYYMMDD"
    echo "    Value3 = Configuration (BIOMER4V1R2 / PSY4V3R1)"
    echo "           Value4 = Data Source (GLOBCOLOUR)"
    echo "    Value5 = Data Type / Variable (chloro, sst, sla)"
    echo "                 Value6 = Mode (pgn)"
    echo " "
    echo "******************************************************* "
    echo " "
    exit 1
}

if [ $# -eq 0 ] ;then
    usage
fi

workdir=/home/cregnier/Gitlab/TEP_CLASS4/script/log
logfile=${workdir}/TEP_CLASS4_${day1}-${day2}.log

# Suppression du flag de controle fin de job
rm -f $PWD/OK.flag

exe="../exe_TEP_CLASS4_multi.py"

qsub -v day1=$day1,day2=$day2,cfg=$cfg,source=$source,typedata=$typedata,mode=$mode,pbsworkdir=$PWD $PWD/${exe}  >> $logfile

echo "Connection successful" >> $logfile
