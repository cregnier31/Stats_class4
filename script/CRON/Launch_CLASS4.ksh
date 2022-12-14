#!/bin/ksh 
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
DATE1=$( /bin/date +%Y%m%d --date='last wednesday -7 day')
DATE2=$( /bin/date +%Y%m%d --date='last tuesday')
DATERUN=$( /bin/date +%Y%m%d --date='next wednesday')
if [ $# -lt 2 ]; then
  echo "USAGE: ${PROGNAME} <typedata> <CONFIG>"
  exit 1
fi

typedata=$1
CONFIG=$2
LOCK_DIR=${PROGDIR}
lock=${LOCK_DIR}/.${PROGNAME}_${typedata}.pid
echo $lock
pid=$( /bin/cat ${lock} 2>/dev/null )
if [ ! -z "${pid}" ]; then
	/bin/kill -0 ${pid} 2>/dev/null && exit 0
fi
echo -n $$ > ${lock} # -n: no line feed/carriage return
case "${typedata}" in
      SLA|SST|profile|aice)
	  # echo "Working with $typedata"
          srcdata="GODAE"
      ;;
      DRIFTER_filtr|DRIFTER)
          srcdata="CMEMS_013_048"
      ;;
      *)
         echo "Config not found"
	 exit 1
      ;;
esac
typemod="pgn"
loglevel=1
nb_files_ok=`ls ${PROGDIR}/../../../../../CRON/log/Rappat-PSY4V3R1-${DATERUN}-*HDCT-OK | wc -l`
nb_files_ok=6
if [ $(echo "$nb_files_ok == 6" | bc) -eq 1 ] ; 
then 
   flag_ok=${PROGDIR}/log/Class4-${CONFIG}-${DATE1}-${DATE2}-${typedata}-OK
   [ -f ${flag_ok} ] && exit 0
   echo "Source the bashrc"
   . /etc/bashrc
   echo "Source Ok"
   # User specific environment
   PATH="$HOME/.local/bin:$HOME/bin:$PATH"
   export PATH
   export MODULEPATH=/home/modules/rules/compilateurs:/home/modules/rules/librairies:/home/modules/rules/outils:/home/modules/rules/applications:$MODULEPATH
   . /home/smer/regnierc/utils/fonc
   module purge
   module load intel/2020.1.217
   module load netcdf/4.7.1-avx512
   module load nco
   DIR_BIN="/home/smer/regnierc/anaconda3/envs/env_py38/bin/python"
   echo  ${PROGDIR}/../TEP_CLASS4_kdtree.py
   ${DIR_BIN} ${PROGDIR}/../TEP_CLASS4_kdtree.py --config=${CONFIG} --date1=${DATE1} --date2=${DATE2}\
   	    --src=${srcdata} --data=${typedata} --typemod=${typemod} --loglevel=${loglevel}
   if [ $? == 0 ]; then
       /bin/touch ${flag_ok}
       rm -f ${lock}
   fi
   exit 0
else
   exit 0
fi
