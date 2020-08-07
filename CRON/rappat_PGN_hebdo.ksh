#!/bin/ksh
# Script à lancer dans un cron tout les jours pour recuperation fichiers quotidiens
# C.REGNIER  Mars 2013
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
if [[ $# -lt 2 ]]
then
  echo $USAGE
  echo "MODEL: PSY3V3R1, PSY2V4R2"
  echo "Type grid : gridT, gridS, icemod..."
exit 1
fi
MODEL=$1
TYPEGRID=$2
LOCK_DIR=${PROGDIR}
LOGDIR=${PROGDIR}/log
lock=${LOCK_DIR}/.${PROGNAME}.pid
pid=$( /bin/cat ${lock} 2>/dev/null )
PASSWD=Pq58OsPE

if [ ! -z "${pid}" ]; then
	/bin/kill -0 ${pid} 2>/dev/null && exit 0
fi
echo -n $$ > ${lock} # -n: no line feed/carriage return

cd ${PROGDIR} || exit 1

#DATERUN=$( /bin/date +%Y%m%d --date='yesterday')
#DATERUN=$( /bin/date +%Y%m%d )
DATERUN=$( /bin/date +%Y%m%d --date='+2 day')
TYPE=`echo $MODEL | cut -c1-4`
TYPEMOD=`echo $MODEL | tr "[A-Z]" "[a-z]"`
DIR_RAPPAT_hdct="/W1PSY4/smer/smer883/SORT/HEBDO/${TYPE}/${TYPEMOD}/hdct/"
DIR_RAPPAT_nwct="/W1PSY4/smer/smer883/SORT/HEBDO/${TYPE}/${TYPEMOD}/nwct"
flag_ok=${PROGDIR}/log/Rappat-${MODEL}-${DATERUN}-${TYPEGRID}-OK
[ -f ${flag_ok} ] && exit 0
case $MODEL in
         PSY3V3R1)
         dir_cougar_hind="/mercator/spsy/spsy003/chain_double/PSY3V3R1/SAM2v1_ORCA025_LIM_IAU_NEMO_3.0/PHYSICAL_MODEL/HINDCAST"
         dir_cougar_now="/mercator/spsy/spsy003/chain_double/PSY3V3R1/SAM2v1_ORCA025_LIM_IAU_NEMO_3.0/PHYSICAL_MODEL/NOWCAST"
         ;;
         PSY3V3R3)
         dir_cougar_hind="/mercator/spsy/spsy003/PSY3V3R3/op/PHYSICAL_MODEL/HINDCAST"
         dir_cougar_hind="/mercator/spsy/mercator/PSY3V3R3/op/PHYSICAL_MODEL/HINDCAST"
         dir_cougar_now="/mercator/spsy/spsy003/PSY3V3R3/op/PHYSICAL_MODEL/NOWCAST"
         dir_cougar_now="/mercator/spsy/mercator/PSY3V3R3/op/PHYSICAL_MODEL/NOWCAST"
         ;;
         PSY4V2R2)
         dir_cougar_hind="/mercator/spsy/spsy003/PSY4V2R2/op/PHYSICAL_MODEL/HINDCAST"
         dir_cougar_hind="/mercator/spsy/mercator/PSY4V2R2/op/PHYSICAL_MODEL/HINDCAST"
         dir_cougar_now="/mercator/spsy/spsy003/PSY4V2R2/op/PHYSICAL_MODEL/NOWCAST"
         dir_cougar_now="/mercator/spsy/mercator/PSY4V2R2/op/PHYSICAL_MODEL/NOWCAST"
	 ;;
	 PSY2V4R2)
         dir_cougar_hind="/mercator/spsy/spsy003/chain_double/PSY2QV4R2/SAM2v1_ATL12_IAU_NEMO_3.0/PHYSICAL_MODEL/DAILY_FORECAST"
         dir_cougar_now="/mercator/spsy/spsy003/chain_double/PSY2QV4R2/SAM2v1_ATL12_IAU_NEMO_3.0/PHYSICAL_MODEL/DAILY_FORECAST"
         ;;
	 *)
          echo "Modele non reconnu  "
          exit 13
         ;;
esac
/usr/bin/ncftpget -u smer883 -p ${PASSWD}  -R  -z -d stdout -F -E  cougar ${DIR_RAPPAT_hdct} ${dir_cougar_hind}/*1dAV*${TYPEGRID}*R${DATERUN}*
if [ $? == 0 ]; then
    /bin/touch ${flag_ok}
    rm -f ${lock}
fi
/usr/bin/ncftpget -u smer883 -p ${PASSWD} -R  -z -d stdout -F -E  cougar ${DIR_RAPPAT_nwct} ${dir_cougar_now}/*1dAV*${TYPEGRID}*R${DATERUN}*
if [ $? == 0 ]; then
    /bin/touch ${flag_ok}
    rm -f ${lock}
fi

exit 0

