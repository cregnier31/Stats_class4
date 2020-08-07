#!/bin/ksh

#set -x
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
LOCK_DIR=${PROGDIR}
DATERUN=$( /bin/date +%Y%m%d --date='-8 day')
if [[ $# -lt 1 ]]
then
  echo $USAGE
  echo "CONFIG"
exit 1
fi

export PYTHONPATH="/home/smer/smer883/Sytoolkit"
export PATH="/usr/bin/python2.3:${PATH}"
CONFIG=$1
EXE="/home/smer/smer883/Creation_pers/Create_pers_daily.py"
OPTIONS="$*"

ulimit -t unlimited
flag_ok=${PROGDIR}/log/Create_pers-CLASS4-${CONFIG}-${DATERUN}-OK
flag_ok_tri=${PROGDIR}/log/Tri-CLASS4-${CONFIG}-${DATERUN}-OK
echo $flag_ok_tri
echo $DATERUN
[ -f ${flag_ok} ] && exit 0
if [ -f ${flag_ok_tri} ]
 then
    lock=${LOCK_DIR}/.${PROGNAME}.pid
    pid=$( /bin/cat ${lock} 2>/dev/null )
    if [ ! -z "${pid}" ]; then
            /bin/kill -0 ${pid} 2>/dev/null && exit 0
    fi
    echo -n $$ > ${lock} # -n: no line feed/carriage re
    cd ${WIND%/*}
    /home/smer/smer859/versions/compilateurs/python/2.6.5/bin/python ${EXE} ${OPTIONS}
    if [ $? == 0 ]; then
      /bin/touch ${flag_ok}
      rm -f ${lock}
    fi
else
  echo "Flag tri ${CONFIG} manquant : ${flag_ok_tri}"
  exit 1
fi
exit $?
