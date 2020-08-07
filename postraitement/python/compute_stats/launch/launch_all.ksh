#!/bin/ksh
GRID=$1
TYPE=$2
YEAR=$3
SYSTEM=$4
typejob=$5

usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 4 arguments :: "
    echo " Valeur1 = GRID 0/2/4 "
    echo " Valeur2 = TYPE SLA SST profile CHL chl "
    echo " Valeur3 = YEAR  "
    echo " Valeur4 = SYSTEM"
    echo " Valeur5 = Type de job lancé : mono ou multi "
    exit 1
}

if [ $# -ne 5 ] ;then
    echo $#
    usage
fi
case "${SYSTEM}" in
        GIOPS_CONCEPTS|PSY3V3R3|PSY4V2R2|PSY4V3R1|PSY2V4R4|HYCOM|FOAM|BLK|BLK2|BIOMER4|FREEBIORYS2)
                ;;
        *)
        echo "Bad system"
        usage
                ;;
esac
case "${TYPE}" in 
      SLA|SST|profile|CHL|chl)
                ;;
      *)
        echo "Bad type"
        usage
                ;;
esac
case "${GRID}" in 
      0|2|4)
                ;;
      *)
        echo "Bad grid"
        usage
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

./compute_stats_kara.ksh ${SYSTEM} ${YEAR}1201 ${YEAR}1231 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}1101 ${YEAR}1130 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}1001 ${YEAR}1031 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0901 ${YEAR}0930 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0801 ${YEAR}0831 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0701 ${YEAR}0731 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0601 ${YEAR}0630 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0501 ${YEAR}0531 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0401 ${YEAR}0430 ${GRID} ${TYPE} ${typejob} 
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0301 ${YEAR}0331 ${GRID} ${TYPE} ${typejob}
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0201 ${YEAR}0228 ${GRID} ${TYPE} ${typejob}
./compute_stats_kara.ksh ${SYSTEM} ${YEAR}0101 ${YEAR}0131 ${GRID} ${TYPE} ${typejob}
###
