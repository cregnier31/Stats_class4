#!/bin/ksh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   >Brief   : Script general du post traitement des fichier CLASS4 quotidiens
#              Permet de calculer les stats MYO pour alimenter site web quality
#              Steps :
#                 2. Connexion a kara,
#                 3. Creation des fichiers RMS_DIFF
#                    avec exe_kara_lecture_class4.py,
#                 4. Creation des fichiers stats ASCII (monoproc)
#                    avec exe_calcul_stats_MYO2.py,
#                 5. Creation du fichier NC_global (monoproc)
#                    au format GODAE avec create_ProdQualStats.py,
#                 6. Rappatriement des fichiers RMS_DIFF, ASCII, NC_global
#                    sur sortref/calval.
#
#   >History :
#              May 2013 : Creation (L.ZAWADZKI)
#              July 2013 : Add new fonction
#              Feb 2018  :  Inside CL4 python code
#              November 2018 : New launcher for the new version of Stats class4
#                               (cszczypta)
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
daily_off=$8
bilan=$6
fmt_ascii=$7
fmt_mask=$5
percent=$9
nblevel=${10}

usage ()
{
    echo " "
    echo "************** Incorrect number of Arguments ******************* "
    echo " "
    echo "                  --> 4 arguments required <-- "
    echo "                         Value1 = Config "
    echo "                        Value2 = Day min "
    echo "                        Value3 = Day max "
    echo "                 Value4 = Type of data: BIO/PHYS"
    echo " " 
    echo "                    --> Optional argument <-- "
    echo "          Value5 = Type of mask: basin/box/bins2d/bins4d"
    echo "                Value6 = Save global stats: on/off"
    echo "           Value7 = Save stats on ASCII fmt files: on/off"
    echo "            Value8 = Save daily time step stats: on/off" 
    echo "     Value9 = Compute misfit and percentile (profile): on/off" 
    echo "            Value10 = Number of considered level profile" 
    echo " "
    echo "***************************************************************** "
    echo " "
    exit 1
}

if [ $# -eq 0 ] ;then
    usage
elif [ -z "${config}"  ] ;then
    echo " "
    echo "********* Configuration is missing *********"
    echo " "
    exit 1
elif [ -z "${day1}"  ] ;then
    echo " "
    echo "********* Day min is missing *********"
    echo " "
    exit 1
elif [ -z "${day2}"  ] ;then
    echo " "
    echo "********* Day max is missing *********"
    echo " "
    exit 1
elif [ -z "${typedata}"  ] ;then
    echo " "
    echo "********* Type of data (BIO/PHYS) is missing *********"
    echo " "
    exit 1
elif [ $# -eq 4 ] ;then
    echo " "
    echo " *************************** DEFAULT CASE **************************"
    echo " "
    echo "     Save stats computed at the daily time step over CMEMS areas "
    echo "                     on netCDF format file"
    echo " "
    echo " *******************************************************************"
    echo " "
fi

if [ $# -eq 5 ] ;then
    echo " "
    echo " ------------------------------------------------------------------------------"
    echo "     -->   Define the type of mask (default case : CMEMS areas)  <--           "
    echo "                Available masks : basin/basin_pol/box/bins2d/bins4d                      "
    echo " ------------------------------------------------------------------------------"
    echo " "
elif [ $# -eq 6 ] ;then
    echo " "
    echo " ------------------------------------------------------------------------------"
    echo "     -->   Define the type of mask (default case : CMEMS areas)  <--           "
    echo "                Available masks : basin/box/bins2d/bins4d                      "
    echo "                                     &                                         "
    echo "        -->   Activate/Deactivate save of stats computed over  <--             "
    echo "                       the whole considered period                             "
    echo " ------------------------------------------------------------------------------"
    echo " "
elif [ $# -eq 7 ] ;then
    echo " "
    echo " ------------------------------------------------------------------------------"
    echo "     -->   Define the type of mask (default case : CMEMS areas)  <--           "
    echo "                Available masks : basin/box/bins2d/bins4d                      "
    echo "                                     &                                         "
    echo "        -->   Activate/Deactivate save of stats computed over  <--             "
    echo "                       the whole considered period                             "
    echo "                                     &                                         "
    echo "            -->   Activate/Deactivate save of stats on   <--                   "
    echo "                          ASCII format file                                    "
    echo " ------------------------------------------------------------------------------"
    echo " "
elif [ $# -eq 8 ] ;then
    echo " "
    echo " ------------------------------------------------------------------------------"
    echo "     -->   Define the type of mask (default case : CMEMS areas)  <--           "
    echo "                Available masks : basin/box/bins2d/bins4d                      "
    echo "                                     &                                         "
    echo "        -->   Activate/Deactivate save of stats computed over  <--             "
    echo "                       the whole considered period                             "
    echo "                                     &                                         "
    echo "            -->   Activate/Deactivate save of stats on   <--                   "
    echo "                          ASCII format file                                    "
    echo "                                     &                                         "
    echo "     -->   Activate/Deactivate save of stats at the daily time step  <--       "
    echo " ------------------------------------------------------------------------------"
    echo " "
elif [ $# -eq 9 ] ;then
    echo " "
    echo " ------------------------------------------------------------------------------"
    echo "     -->   Define the type of mask (default case : CMEMS areas)  <--           "
    echo "                Available masks : basin/box/bins2d/bins4d                      "
    echo "                                     &                                         "
    echo "        -->   Activate/Deactivate save of stats computed over  <--             "
    echo "                       the whole considered period                             "
    echo "                                     &                                         "
    echo "            -->   Activate/Deactivate save of stats on   <--                   "
    echo "                          ASCII format file                                    "
    echo "                                     &                                         "
    echo "     -->   Activate/Deactivate save of stats at the daily time step  <--       "
    echo "                                     &                                         "
    echo "     -->   Activate bias and percentile computation for temperature  <--       "
    echo "                             and salinity                                      "
    echo " ------------------------------------------------------------------------------"
    echo " "
elif [ $# -eq 10 ] ;then
    echo " "
    echo " ------------------------------------------------------------------------------"
    echo "     -->   Define the type of mask (default case : CMEMS areas)  <--           "
    echo "                Available masks : basin/box/bins2d/bins4d                      "
    echo "                                     &                                         "
    echo "        -->   Activate/Deactivate save of stats computed over  <--             "
    echo "                       the whole considered period                             "
    echo "                                     &                                         "
    echo "            -->   Activate/Deactivate save of stats on   <--                   "
    echo "                          ASCII format file                                    "
    echo "                                     &                                         "
    echo "     -->   Activate/Deactivate save of stats at the daily time step  <--       "
    echo "                                     &                                         "
    echo "     -->   Activate bias and percentile computation for temperature  <--       "
    echo "                             and salinity                                      "
    echo "                                     &                                         "
    echo "     -->   Change the number of considered levels to compute profile  <--      "
    echo "                             T and S statistics                                "
    echo " ------------------------------------------------------------------------------"
    echo " "
fi

case "${config}" in
        FOAM|GIOPS|GIOPS|BLK|PSY3V3R3|HYCOM_RTOFS|PSY4V2R2|PSY4V3R1|BIOMER4|FREEBIORYS2|NERSC|BIOMER4V2|ENSMEAN)
                ;;
        *)
        echo "Config not found: Define a new environment_config.cfg file"
        exit 1
                ;;
esac

case "${typedata}" in 
      BIO|PHYS)
                ;;
      *)
        echo "Bad typedata => BIO/PHYS"
        exit 1
                ;;
esac

if [ $# -eq 5 ] ;then
    case "${fmt_mask}" in 
          basin|basin_pol|box|bins2d|bins2d_arc|bins2d_ant|bins4d)
                    ;;
          *)
            echo "Bad mask => basin/basin_pol/box/bins2d/bins4d/bins2d_arc|bins2d_ant"
            exit 1
                    ;;
    esac
elif [ $# -eq 6 ] ;then
    case "${bilan}" in 
          on|off)
                    ;;
          *)
            echo "Bad type of value (Value6: Bilan) => on/off"
            exit 1
                    ;;
    esac
elif [ $# -eq 7 ] ;then
    case "${fmt_ascii}" in 
          on|off)
                    ;;
          *)
            echo "Bad type of value (Value7: Fmt Ascii) => on/off"
            exit 1
                    ;;
    esac
elif [ $# -eq 8 ] ;then
    case "${daily_off}" in 
          on|off)
                    ;;
          *)
            echo "Bad type of value (Value8: Daily off) => on/off"
            exit 1
                    ;;
    esac
elif [ $# -eq 9 ] ;then
    case "${percent}" in 
          on|off)
                    ;;
          *)
            echo "Bad type of value (Value9: Percent) => on/off"
            exit 1
                    ;;
    esac
elif [ $# -eq 10 ] ;then
    case "${nblevel}" in 
          50|75)
                    ;;
          *)
            echo "profile level file not found: Define a new profile file"
            exit 1
                    ;;
    esac
fi

module load openmpi/openmpi-1.8.5
module load intel/intel-18
workdir=/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V5/postraitement/python/compute_stats/log
cfgfile=../environment_${config}.cfg

logfile=${workdir}/CLASS4_${config}_${day1}-${day2}.log
echo $cfgfile
# Suppression du flag de controle fin de job
rm -f $PWD/OK.flag

if [ "${daily_off}" == "off" ] ; then
    exe="../exe_kara_Lecture_class4_multi_bilan.py"
elif [ "${daily_off}" != "off" ] ; then
    exe="../exe_kara_Lecture_class4_multi_timeserie.py"
fi

if [ $# -eq 4 ] ;then
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata} $PWD/${exe}  >> $logfile
elif  [ $# -eq 5 ] ; then
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata},fmt_mask=${fmt_mask} $PWD/${exe}  >> $logfile
elif  [ $# -eq 6 ] ; then
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata},fmt_mask=${fmt_mask},bilan=${bilan} $PWD/${exe}  >> $logfile
elif  [ $# -eq 7 ] ; then
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata},fmt_mask=${fmt_mask},bilan=${bilan},fmt_ascii=${fmt_ascii} $PWD/${exe}  >> $logfile
elif  [ $# -eq 8 ] ; then
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata},fmt_mask=${fmt_mask},bilan=${bilan},fmt_ascii=${fmt_ascii},daily_off=${daily_off} $PWD/${exe}  >> $logfile
elif  [ $# -eq 9 ] ; then
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata},fmt_mask=${fmt_mask},bilan=${bilan},fmt_ascii=${fmt_ascii},daily_off=${daily_off},percent=${percent} $PWD/${exe}  >> $logfile
else
  qsub -v day1=$day1,day2=$day2,cfg=$cfgfile,pbsworkdir=$PWD,type=${typedata},fmt_mask=${fmt_mask},bilan=${bilan},fmt_ascii=${fmt_ascii},daily_off=${daily_off},percent=${percent},nblevel=${nblevel} $PWD/${exe}  >> $logfile
fi

echo "Connection successful" >> $logfile

