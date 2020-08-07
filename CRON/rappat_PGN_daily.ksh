#!/bin/ksh
# Script à lancer dans un cron tout les jours pour recuperation fichiers quotidiens
# C.REGNIER  Mars 2013
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
if [[ $# -lt 2 ]]
then
  echo $USAGE
  echo "MODEL: PSY3QV3R1, PSY2QV4R2"
  echo "Type grid : gridT, gridS, icemod..."
exit 1
fi
MODEL=$1
TYPEGRID=$2
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

DATERUN=$( /bin/date +%Y%m%d )
#DATERUN=$( /bin/date +%Y%m%d --date='yesterday')
DIR_RAPPAT="/W1PSY4/smer/smer883/${MODEL}/"
flag_ok=${PROGDIR}/log/Rappat-${MODEL}-${DATERUN}-${TYPEGRID}-OK
[ -f ${flag_ok} ] && exit 0
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
exit 0

