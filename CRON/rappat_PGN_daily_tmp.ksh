#!/bin/ksh
# Script à lancer dans un cron tout les jours pour recuperation fichiers quotidiens
# C.REGNIER  Mars 2013
function d2j {
   
# translate std date to Julian day
   # routine Lucas Nouel
   typeset -i day month year tmpmonth tmpyear
   dateD=$1
   day=$(echo $dateD | cut -c7-8)
   month=$(echo $dateD | cut -c5-6)
   year=$( echo $dateD | cut -c1-4)
   ((tmpmonth = 12 * year + month - 3))
   ((tmpyear = tmpmonth / 12))
   val=$(( (734 * tmpmonth + 15) / 24 -  2 * tmpyear + tmpyear/4 - tmpyear/100 + tmpyear/400 + day - 712164 ))
   echo $val
}

function  j2d {
   # translate Julianday to std date
   # routine Lucas Nouel
   typeset -i day month year tmpday centuries
   typeset -Z2 day month
   ((tmpday = $1 + 712164))
   ((centuries = (4 * tmpday - 1) / 146097))
   ((tmpday += centuries - centuries/4))
   ((year = (4 * tmpday - 1) / 1461))
   ((tmpday -= (1461 * year) / 4))
   ((month = (10 * tmpday - 5) / 306))
   ((day = tmpday - (306 * month + 5) / 10))
   ((month += 2))
   ((year += month/12))
   ((month = month % 12 + 1))
   echo $year$month$day
}


PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
if [[ $# -lt 1 ]]
then
  echo $USAGE
  echo "MODEL: PSY3QV3R1, PSY2QV4R2"
exit 1
fi
MODEL=$1
LOCK_DIR=${PROGDIR}
LOGDIR=${PROGDIR}/log
lock=${LOCK_DIR}/.${PROGNAME}.pid
PASSWD=Pq58OsPE
pid=$( /bin/cat ${lock} 2>/dev/null )
if [ ! -z "${pid}" ]; then
	/bin/kill -0 ${pid} 2>/dev/null && exit 0
fi
echo -n $$ > ${lock} # -n: no line feed/carriage return

cd ${PROGDIR} || exit 1

DATE_INIT="20140515"
DATE_FIN="20140515"
juldateini=$( d2j ${DATE_INIT} )
juldatefin=$( d2j ${DATE_FIN} )


DIR_RAPPAT="/W1PSY4/smer/smer883/${MODEL}/"

for curday_julian in  $( seq ${juldateini} ${juldatefin} ); do 
  #for TYPEGRID in gridT gridS grid2D ; do
  for TYPEGRID in gridT ; do
    DATERUN=$( j2d ${curday_julian} )
    echo $DATERUN
    flag_ok=${PROGDIR}/log/Rappat-${MODEL}-${DATERUN}-${TYPEGRID}-OK
    echo $flag_ok
    [ -f ${flag_ok} ] && break
    case $MODEL in
             PSY3QV3R1)
             dir_cougar="/mercator/spsy/spsy003/chain_double/PSY3QV3R1/SAM2v1_ORCA025_LIM_IAU_NEMO_3.0/PHYSICAL_MODEL/DAILY_FORECAST"
             ;;
             PSY3QV3R3)
             dir_cougar="/mercator/spsy/mercator/PSY3V3R3/op/PHYSICAL_MODEL/DAILY_FORECAST"
             ;;
             PSY4QV2R2)
             dir_cougar="/mercator/spsy/mercator/PSY4V2R2/op/PHYSICAL_MODEL/DAILY_FORECAST"
    	     ;;
             PSY2QV4R2)
             dir_cougar="/mercator/spsy/spsy003/chain_double/PSY2QV4R2/SAM2v1_ATL12_IAU_NEMO_3.0/PHYSICAL_MODEL/DAILY_FORECAST"
             ;;
             PSY2QV4R4)
             dir_cougar="/mercator/spsy/spsy003/PSY2V4R4/op/PHYSICAL_MODEL/DAILY_FORECAST"
             ;;
             PRESAL36QV1R1)
             dir_cougar="/mercator/spsy/spsy004/PRESAL36V1R1/RUN1/PHYSICAL_MODEL/DAILY_FORECAST"
             dir_cougar="/mercator/spsy/spsy004/PRESAL36V1R1/RUN1/PHYSICAL_MODEL/DAILY_FORECAST"
             dir_cougar="/mercator/spsy/mercator/PRESAL36V1R1/op/PHYSICAL_MODEL/DAILY_FORECAST"
    	 ;;
    	 *)
              echo "Modele non reconnu  "
              exit 13
             ;;
    esac
    /usr/bin/ncftpget -u smer883 -p ${PASSWD} -R  -z -d stdout -F -E  cougar ${DIR_RAPPAT} ${dir_cougar}/*1dAV*${TYPEGRID}*R${DATERUN}*
    if [ $? == 0 ]; then
        /bin/touch ${flag_ok}
        rm -f ${lock}
    fi
  done
done
exit 0

