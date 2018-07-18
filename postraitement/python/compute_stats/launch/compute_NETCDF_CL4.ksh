#!/bin/ksh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   >Brief   : Script general du post traitement des fichier CLASS4 quotidiens 
#              Permet de generer les stats de physique et de bio au format 
#              netCDF pour alimenter le site d evaluation de CMEMS
#  
#   >History :
#              Mars 2018 : Creation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}

. ${PROGDIR}/../../../utils/myfunctions.ksh


config=$1
day1=$2
day2=$3
type=$4

usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 4 arguments :: "
    echo " Valeur1 = Config "
    echo " Valeur2 = Jour min "
    echo " Valeur3 = Jour max "
    echo " Valeur4 = Type of data (PHYS or BIO)"
    exit 1
}

if [ -z "${config}" ]; then
    usage
fi
if [ $# -ne 4 ] ;then
    echo $#
    usage
fi
case "${config}" in
        PSY3V3R1|PSY3V3R3|GIOPS|PSY4V2R2|PSY4V3R1|PSY2V4R4|HYCOM|FOAM|BLK|BIOMER4)
                ;;
        *)
        usage
                ;;
esac


export PYTHONPATH=$PYTHONPATH:../../module/

dir=../
workdir=${dir}/log
cfgfile=${dir}/environment_${config}.cfg
logfile=${workdir}/CLASS4_${config}_${day1}-${day2}.log

#  3. Calcul des statistiques regionales, fichiers netCDF
#module load ipython
../create_ProdQualStats.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --type=$type

