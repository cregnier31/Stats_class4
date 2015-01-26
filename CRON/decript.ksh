#!/bin/ksh
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
LOCK_DIR=${PROGDIR}
DATERUN=$( /bin/date +%Y%m%d --date='-6 day')
#DATERUN=$( /bin/date +%Y%m%d --date='-9 day')
echo $DATERUN
flag_ok=${PROGDIR}/log/Decript-CLASS4_FOAM-${DATERUN}-OK
flag_ok_rappat=${PROGDIR}/log/Rappat-CLASS4_FOAM-${DATERUN}-OK
echo $flag_ok
[ -f ${flag_ok} ] && exit 0
if [ -f ${flag_ok_rappat} ]
 then
    lock=${LOCK_DIR}/.${PROGNAME}.pid
    pid=$( /bin/cat ${lock} 2>/dev/null )
    if [ ! -z "${pid}" ]; then
            /bin/kill -0 ${pid} 2>/dev/null && exit 0
    fi
    echo -n $$ > ${lock} # -n: no line feed/carriage re
    cd /W1PSY4/smer/smer883/CLASS4_FOAM/  || exit 1
    files=`ls *${DATERUN}*FOAM*.enc`
    for file in $files; do
      fic2=`echo ${file%????}`
      echo "Decript $file"
      openssl enc -d -aes-256-cbc -pass pass:ire15aus6 -in $file > $fic2
      mv  $fic2 decript/
      echo "Decript OK"
      gunzip -f decript/$fic2
      echo "Detar OK $fic2"
      rm -f $file
    done
    if [ $? == 0 ]; then
        /bin/touch ${flag_ok}
        rm -f ${lock}
    fi
else
  echo "Flag Rappat CLASS4 manquant : ${flag_ok_rappat}"
  exit 1
fi
 exit 0
