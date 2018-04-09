#!/bin/ksh
GRID=$1
TYPE=$2
YEAR=$3
SYSTEM=$4


usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 4 arguments :: "
    echo " Valeur1 = GRID 0/2/4 "
    echo " Valeur2 = TYPE SLA SST profile "
    echo " Valeur3 = YEAR  "
    echo " Valeur4 = SYSTEM"
    exit 1
}

if [ $# -ne 4 ] ;then
    echo $#
    usage
fi
case "${SYSTEM}" in
        GIOPS_CONCEPTS|PSY3V3R3|PSY4V2R2|PSY4V3R1|PSY2V4R4|HYCOM|FOAM|BLK|BLK2)
                ;;
        *)
        echo "Bad system"
        usage
                ;;
esac
case "${TYPE}" in 
      SLA|SST|profile)
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
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}1201 ${YEAR}1231 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}1101 ${YEAR}1130 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}1001 ${YEAR}1031 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0901 ${YEAR}0930 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0801 ${YEAR}0831 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0701 ${YEAR}0731 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0601 ${YEAR}0630 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0501 ${YEAR}0531 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0401 ${YEAR}0430 ${GRID} ${TYPE} 
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0301 ${YEAR}0331 ${GRID} ${TYPE}
#./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0201 ${YEAR}0228 ${GRID} ${TYPE} 
./compute_stats_naviti.ksh ${SYSTEM} ${YEAR}0101 ${YEAR}0131 ${GRID} ${TYPE} 
###
