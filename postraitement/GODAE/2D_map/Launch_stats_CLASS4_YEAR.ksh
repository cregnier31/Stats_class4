#!/bin/ksh
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
ulimit -s unlimited
if [[ $# -lt 2 ]]
then
  echo $USAGE
  echo "MODEL: PSY3V3R1, PSY2V4, PSY4, GLORYS  YEAR "
  exit 1
fi
MODEL=$1
YEAR=$2

case ${MODEL} in
  PSY3V3R3)
   type="ORCA025_LIM"
   zone="T"
   MOD="PSY3"
  ;;
  PSY4V2R2 | PSY4QV2R2 | PSY4V3R1)
   type="ORCA12"
   zone="T"
   MOD="PSY4"
  ;;
  default)
  echo "Modele no défini"
  ;;
esac
LOCK_DIR=${PROGDIR}
LOGDIR=${PROGDIR}/log
lock=${LOCK_DIR}/.${PROGNAME}_${MODEL}.pid
echo $lock
pid=$( /bin/cat ${lock} 2>/dev/null )
if [ ! -z "${pid}" ]; then
        /bin/kill -0 ${pid} 2>/dev/null && exit 0
fi
echo -n $$ > ${lock} # -n: no line feed/carriage return
cd ${PROGDIR} || exit 1
curdate=${YEAR}
echo $curdate
plotIDLFile=lance_idl_CLASS4_${MODEL}_${curdate}.pro
flag_ok=${PROGDIR}/log/${PROGNAME}-${curdate}-${MODEL}-OK
echo $flag_ok
#[ -f ${flag_ok} ] && exit 0
[ ! -d ${PROGDIR}/log ] && mkdir -p ${PROGDIR}/log


# Creation idl launcher
idl=/home/modules/versions/64/centos7/idl/8.4/idl/bin/idl
IDL_DIR=/home/modules/versions/64/centos7/idl/8.4/idl/
IDL_DIR_BIN=${idl}
IDL_TOOLBOX=/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic/
IDL_LOCAL_DIR=${PROGDIR}
OUTPUT_DIR="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/${MODEL}/Class4_pics/Cartes/GODAE/"
for var in SLA SST T_S; do 
   DIR_OUT="${OUTPUT_DIR}${var}/${YEAR}"
   [ ! -d ${DIR_OUT} ] && mkdir -p ${DIR_OUT}
done
dir_input="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/${MODEL}/Stats_GODAE/RMS_DIFF/bins2deg/"
#dir_input="/naviti/data2/cregnier/Stats_GODAE/RMS_DIFF/${MOD}/"
export ITT_DIR="/home/modules/versions/64/centos7/idl/8.4"
export IDL_DIR="/home/modules/versions/64/centos7/idl/8.4/idl84"
export IDL_DIR_BIN="/home/modules/versions/64/centos7/idl/8.4/idl/bin"
export IDL_PATH="+$IDL_LOCAL_DIR:+$IDL_TOOLBOX:<IDL_DEFAULT>"
echo "cd, '${IDL_TOOLBOX}'" > ${plotIDLFile}
echo "@compile" >> ${plotIDLFile}
echo "cd, '${PROGDIR}'"  >> ${plotIDLFile}
echo ".compile compute_stats_class4_geo_supobs_GODAE_YEAR" >> ${plotIDLFile}
echo ".compile tracer_stats_gloCLASS4_pcolor_supobs_GODAE" >> ${plotIDLFile}
echo ".compile tracer_stats_gloCLASS4_pcolor_supobs_GODAE_2D"  >> ${plotIDLFile}
echo ".compile Def_param_bulletin" >> ${plotIDLFile}
echo "@param_class4" >> ${plotIDLFile}
echo "@param" >> ${plotIDLFile}
echo "compute_stats_class4_geo_supobs_GODAE_YEAR,DIR_OUT='${OUTPUT_DIR}',DIR_INPUT='${dir_input}',MODEL='${MODEL}',YEAR='${YEAR}',QUART='${QUART}',zone='${zone}'" >> ${plotIDLFile}
echo "exit" >> ${plotIDLFile}
${idl} ${plotIDLFile}
if [ $? == 0 ]; then
    /bin/touch ${flag_ok}
    rm -f ${lock}
fi
exit 0


