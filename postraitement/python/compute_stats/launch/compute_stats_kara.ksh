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
#              August 2018  :  Run stats in kara 
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
typejob=$6

usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 6 arguments :: "
    echo " Valeur1 = Config "
    echo " Valeur2 = Jour min "
    echo " Valeur3 = Jour max "
    echo " Valeur4 = Resolution grille stats "
    echo " Valeur5 = Type de donnee "
    echo " Valeur6 = Type de job lancé : mono ou multi "
    exit 1
}

if [ -z "${config}" ]; then
    usage
fi
if [ $# -ne 6 ] ;then
    echo $#
    usage
fi
case "${config}" in
        PSY3V3R1|PSY3V3R1_2|PSY3V3R1_3|GIOPS_CONCEPTS|PSY3V3R3|PSY4V2R2|PSY4V3R1|PSY2V4R4|HYCOM|FOAM|BLK|BLK2|BIOMER4|FREEBIORYS2)
                ;;
        *)
        echo "Bad config type "
        exit 1
                ;;
esac
case "${typedata}" in 
      SLA|SST|profile|CHL|chl)
                ;;
      *)
        echo "Bad typedata => SLA|SST|profile|CHL"
        exit 1
                ;;
esac
case "${typejob}" in 
      mono|multi)
                ;;
      *)
        echo "Bad job queue => mono|multi"
        exit 1
                ;;
esac


module load openmpi/openmpi-1.8.5
module load intel/intel-18
workdir=/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/python/compute_stats/log
cfgfile=../environment_${config}.cfg
logfile=${workdir}/CLASS4_${config}_${day1}-${day2}.log

echo "Work Directory            :: $workdir" >> $logfile
# Suppression du flag de controle fin de job
rm -f $PWD/OK.flag
echo $logfile
if [ "${typegrid}" -eq "0" ] ; then 
  ## Stats bins
  echo "---- Gridtype ${typegrid} ---"
  if [ "${typejob}" == "mono" ] ; then
      exe="../exe_kara_Lecture_class4_mono.py"
  elif [ "${typejob}" == "multi" ] ; then
      echo "job multi"
      exe="../exe_kara_Lecture_class4_multi.py"
  fi
  echo "Launch qsub"
  echo qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/${exe}
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/${exe}  >> $logfile
elif  [ "${typegrid}" -eq "2" ] ; then 
  exe="../exe_kara_Lecture_class4_bins2deg.py"
  ## Stats bins2deg
  echo "Gridtype ${typegrid} "
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/${exe}  >> $logfile
elif  [ "${typegrid}" -eq "4" ] ; then 
  ## Stats bins4deg
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/exe_kara_Lecture_class4_bins4deg.py  >> $logfile
else
  echo "Bad ${typegrid} "
  exit 2
fi

echo "Connection successful" >> $logfile
#  3. Calcul des statistiques regionales, fichiers ascii

#./exe_calcul_stats_MYO2.py --day1=$day1 --day2=$day2 --cfg=$cfgfile

