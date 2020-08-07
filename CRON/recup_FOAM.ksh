#!/bin/ksh
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
LOCK_DIR=${PROGDIR}
DATERUN=$( /bin/date +%Y%m%d --date='-6 day')
YEAR=`echo $DATERUN | cut -c1-4`
echo "DATE : $DATERUN"
flag_ok=${PROGDIR}/log/Rappat-CLASS4_FOAM-${DATERUN}-OK
lock=${LOCK_DIR}/.${PROGNAME}.pid
pid=$( /bin/cat ${lock} 2>/dev/null )
if [ ! -z "${pid}" ]; then
        /bin/kill -0 ${pid} 2>/dev/null && exit 0
fi
echo -n $$ > ${lock} # -n: no line feed/carriage re
cd ${PROGDIR} || exit 1
echo $flag_ok
[ -f ${flag_ok} ] && exit 0
cd /W1PSY4/smer/smer883/CLASS4_FOAM/  || exit 1
ncftpget -d stdout -R ftp://usgodae.org/pub/outgoing/GODAE_class4/${YEAR}/${DATERUN}/*FOAM_orca025*
if [ $? == 0 ]; then
    /bin/touch ${flag_ok}
    rm -f ${lock}
fi
exit 0
