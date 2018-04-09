#!/bin/ksh
## Lancement des stats sur yuki sc : C.REGNIER Octobre 2012
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}
. ${PROGDIR}/fonc


CONFIG=$1
DATE1=$2
DATE2=$3
TYPE_GRID=$4
usage ()
{
    echo "Nb d'argument incorrects :: "
    echo "Necessite 4 arguments :: "
    echo " Valeur1 = CONFIG "
    echo " Valeur2 = Date initiale"
    echo " Valeur3 = Date finale"
    echo " Valeur4 = Resolution de la grille "
    exit 1
}

if [ $# -ne 4 ] ;then
    echo $#
    usage
fi
case "${CONFIG}" in
        GLORYS2V4|FOAM|CGLORS|ORAS5|ENSEMBLE|GLORYS12V1|PSY2V4R2|PSY3V3R3|PSY3V3R1|PSY4V2R1|PSY4V3R1|PSY4V2R2|PSY2V4R4)
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
DIR_LOG='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/log_'${TYPE}'/'${DATE1}'_'${DATE2}'/'
#DIR_LOG='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/log_'${TYPE}'/CORA4/'${DATE1}'_'${DATE2}'/'
#DIR_LOG='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/log_'${TYPE}'/'${DATE1}'_'${DATE2}'/'
job_script="${file_tmp}/Launch_STATS_${DATE1}_${DATE2}_${CONFIG}.pbs"
PBS_HEADER=${PROGDIR}/envelope_CLASS4_STATS.txt
mkdir -p ${file_tmp}

cat > ${job_script} <<_EOF_
#!/bin/ksh
#PBS -N ${CONFIG}_STATS_CLASS4_select_${DATE1}_${DATE2}
#PBS -o ${DIR_LOG}/STATS_CLASS4_select_${DATE1}_${DATE2}.out
#PBS -e ${DIR_LOG}/STATS_CLASS4_select_${DATE1}_${DATE2}.err
$( sed -e "s/__NBPROC__/1/" $PBS_HEADER )
module load ipython/ipython-0.13
module load nco/nco-4.3.2
_EOF_
echo "echo \$(date) STATS CLASS4 for JRUN ${JRUN}" >> ${job_script}
cat >> ${job_script} <<_EOF_ 
python ${PROGDIR}/traitement_class4_select.py $CONFIG $DATE1 $DATE2 $GRID_TYPE
_EOF_

qsub ${job_script}
