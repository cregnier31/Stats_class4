#!/bin/ksh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   >Brief   : Script general du post traitement des fichier CLASS4 quotidiens 
#              rappatries de arctique3.
#              Steps :
#  	          1. Rappatriement des fichiers depuis arctique3,
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
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}

. ${PROGDIR}/../../../utils/myfunctions.ksh


config=$1
day1=$2 #'20130101'
day2=$3 #'20130331'
typegrid=$4
typedata=$5

usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 5 arguments :: "
    echo " Valeur1 = Config "
    echo " Valeur2 = Jour min "
    echo " Valeur3 = Jour max "
    echo " Valeur4 = Resolution grille stats "
    echo " Valeur5 = Type de donnee "
    exit 1
}

if [ -z "${config}" ]; then
    usage
fi
if [ $# -ne 5 ] ;then
    echo $#
    usage
fi
case "${config}" in
        PSY3V3R1|PSY3V3R1_2|PSY3V3R1_3|GIOPS_CONCEPTS|PSY3V3R3|PSY4V2R2|PSY4V3R1|PSY2V4R4|HYCOM|FOAM|BLK|BLK2)
                ;;
        *)
        usage
                ;;
esac
case "${typedata}" in 
      SLA|SST|profile)
                ;;
      *)
        usage
                ;;
esac

module load ipython/ipython-0.13 
module load intel/intel-15
module load openmpi/openmpi-1.7.1

##module load ipython/ipython-1.1
##module load intel/intel-15
##module load openmpi/openmpi-1.8.5
#arc3indir=/W1PSY4/smer/smer883/CLASS4_MERCATOR/OUTPUT
arc3indir=/W1PSY4/smer/smer883/CLASS4_FOAM/decript
workdir=/home/cregnier/DEV_naviti/TEP_CLASS4_GODAE/log
cfgfile=/home/cregnier/DEV_naviti/TEP_CLASS4_GODAE/postraitement/PY_EXE/environment_${config}.cfg
logfile=${workdir}/CLASS4_${config}_${day1}-${day2}.log
ftpget_arc3=/home/cregnier/Script_log_meteo/ftpget_arc3.ksh

echo "Arctique3 Input Directory :: $arc3indir" > $logfile
echo "Work Directory            :: $workdir" >> $logfile

export IPYTHONDIR=/naviti/data2/cregnier/ipython/
#export IPYTHONDIR=/home/cregnier/.ipython/
# Suppression du flag de controle fin de job
rm -f $PWD/OK.flag

if [ "${typegrid}" -eq "0" ] ; then 
  ## Stats bins
  echo "Gridtype ${typegrid} "
##  if [ "${config}" = "PSY4V3R1" ] ; then
##  else
     exe="../exe_naviti_Lecture_class4.py"
##  fi
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/${exe}  >> $logfile
  #echo "qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD $PWD/exe_nautilus_Lecture_class4.py"
elif  [ "${typegrid}" -eq "2" ] ; then 
##  if [ "${config}" = "PSY4V3R1" ] ; then
##  else
     exe="../exe_naviti_Lecture_class4_bins2deg.py"
##     exe="exe_naviti_Lecture_class4_bins2deg_best.py"
##  fi
  ## Stats bins2deg
  echo "Gridtype ${typegrid} "
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/${exe}  >> $logfile
  #qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD $PWD/exe_nautilus_Lecture_class4_bins2deg.py  >> $logfile
elif  [ "${typegrid}" -eq "4" ] ; then 
  ## Stats bins4deg
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/exe_naviti_Lecture_class4_bins4deg.py  >> $logfile
else
  echo "Bad ${typegrid} "
  exit 2
fi

echo "Connection successful" >> $logfile
##
#   # Attente fin du job
#while [ ! -f $PWD/OK.flag ] ; do
#    sleep 1
#done

#  3. Calcul des statistiques regionales, fichiers ascii

#./exe_calcul_stats_MYO2.py --day1=$day1 --day2=$day2 --cfg=$cfgfile

