#!/bin/ksh
## Lancement des stats sur yuki sc : C.REGNIER Octobre 2012
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}
. ${PROGDIR}/fonc


JRUN=$1
CONFIG=$2
TYPE_GRID=$3
usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 2 arguments :: "
    echo " Valeur1 = Date du RUN"
    echo " Valeur2 = CONFIG "
    echo " Valeur3 = Resolution de la grille "
    exit 1
}

if [ -z "${JRUN}" ]; then
    usage
fi
if [ $# -ne 3 ] ;then
    echo $#
    usage
fi
case "${CONFIG}" in
        PSY2V4R3|PSY2V4R2|PSY3V3R3|PSY3V3R1|PSY4V2R1|PSY4V2R2|PSY2V4R4)
                ;;
        *)
        usage
                ;;
esac


. ${PROGDIR}/fonc

TYPE=`echo ${CONFIG} | cut -c-4`
file_tmp=${PROGDIR}'/tmp/'${TYPE}'/'
julrun=`d2j ${JRUN}`
GRID_TYPE=${TYPE_GRID}
DIR_LOG='/home/ext/mr/smer/regnierc/SAVE/DEV/TEP_CLASS4_trunk/postraitement/log_'${TYPE}'/'
job_script="${file_tmp}/Launch_STATS_${JRUN}_${CONFIG}.pbs"
SBATCH_HEADER=${PROGDIR}/envelope_CLASS4_STATS.txt
mkdir -p ${file_tmp}

cat > ${job_script} <<_EOF_
#!/bin/ksh
#SBATCH -J ${CONFIG}_STATS_CLASS4_${JRUN}
#SBATCH -o ${DIR_LOG}/STATS_CLASS4_${JRUN}.out
#SBATCH -e ${DIR_LOG}/STATS_CLASS4_${JRUN}.err
$( sed -e "s/__numtask_job__/1/" $SBATCH_HEADER )
_EOF_
echo "echo \$(date) STATS CLASS4 for JRUN ${JRUN}" >> ${job_script}
cat >> ${job_script} <<_EOF_ 
python ${PROGDIR}/traitement_class4_WEEKLY.py $JRUN $CONFIG $GRID_TYPE
_EOF_

sbatch ${job_script}
