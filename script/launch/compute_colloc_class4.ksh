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

. ${PROGDIR}/../../postraitement/utils/myfunctions.ksh


year=$1
month=$2
system=$3

usage ()
{
    echo " "
    echo "*********** Incorrect number of Arguments ************ "
    echo " "
    echo "           --> 3 arguments required <-- "
    echo "                 Value1 = Year "
    echo "                Value2 = Month "
    echo "                Value3 = System "
    echo " "
    echo "******************************************************* "
    echo " "
    exit 1
}

if [ $# -eq 0 ] ;then
    usage
elif [ -z "${year}"  ] ;then
    echo " "
    echo "********* Year is missing *********"
    echo " "
    exit 1
elif [ -z "${month}"  ] ;then
    echo " "
    echo "********* Month is missing *********"
    echo " "
    exit 1
elif [ -z "${system}"  ] ;then
    echo " "
    echo "********* System is missing *********"
    echo " "
    exit 1
fi

module load openmpi/openmpi-1.8.5
module load intel/intel-18
workdir=/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/script/log/
logfile=${workdir}/CLASS4_${year}-${month}.log

# Suppression du flag de controle fin de job
rm -f $PWD/OK.flag

exe="./exe_kara_class4_multi12.py"
#exe="./exe_kara_class4_multi2.py"

qsub -v year=$year,month=$month,system=${system},pbsworkdir=$PWD $PWD/${exe}  >> $logfile

echo "Connection successful" >> $logfile

