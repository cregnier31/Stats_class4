#!/bin/ksh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   >Brief   : Script general du post traitement des fichier CLASS4 quotidiens 
#              Permet de calculer les stats MYO pour alimenter site web quality 
#              Steps :
#  	          2. Connexion a nautilus,
#                 3. Creation des fichiers RMS_DIFF 
#  	  	 avec exe_nautilus_lecture_class4.py,
#                 4. Creation des fichiers stats ASCII (monoproc)
#  	  	 avec exe_calcul_stats_MYO2.py,
#                 5. Creation du fichier NC_global (monoproc)
#  	  	 au format GODAE avec create_ProdQualStats.py,
#                 6. Rappatriement des fichiers RMS_DIFF, ASCII, NC_global
#  	  	 sur sortref/calval.
#  
#   >History :
#              May 2013 : Creation (L.ZAWADZKI)
#              July 2013 : Add new fonction
#              Feb 2018  :  Inside CL4 python code
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
typedata=$4

usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 4 arguments :: "
    echo " Valeur1 = Config "
    echo " Valeur2 = Jour min "
    echo " Valeur3 = Jour max "
    echo " Valeur4 = Type of data (CHL, TEMP, PSAL, SLA, SST)"
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

#  3. Calcul des statistiques regionales, fichiers ascii
module load ipython
../exe_calcul_stats_CL4.py --day1=$day1 --day2=$day2 --cfg=$cfgfile --datatype=$typedata

