#!/bin/ksh
## Laucher for CLASS4 CORA5 in KARA
## C.REGNIER Janv 2021
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}


if [ $# -lt 6 ]; then
    echo "USAGE: ${PROGNAME} <CONFIG> <DATE1><DATE2><NB_PROC>><SRC><DAYMAX> "
    echo "USAGE: ./${PROGNAME} GLORYS12V1-free 20050801 20050831 32 CORA5.2 20070101"
    exit 1
fi
CONFIG=$1
DATE1=$2
DATE2=$3
NB_PROC=$4
SRC=$5
DAYMAX=$6
dir_sub="/home/cregnier/Gitlab/TEP_CLASS4/script/sub/"
DIR_LOG="/kara/data1/cregnier/log/CORA5/"
TYPEMOD='pgn'  ## allege
### 
DATERUN=${DATE1}
job_script="${dir_sub}/Launch_${DATERUN}_${CONFIG}_nbproc${NB_PROC}.pbs"
PBS_HEADER=${PROGDIR}/envelope_CLASS4_mono.txt
echo ${PROGDIR}/envelope_CLASS4_mono.txt
#PBS_HEADER=${PROGDIR}/envelope_CLASS4_multi.txt
cat > ${job_script} <<_EOF_
#!/bin/ksh
#SBATCH -J CLASS4_CORA5_${CONFIG}_${DATERUN}
#SBATCH -e ${DIR_LOG}/CLASS4_CORA5_${CONFIG}_${DATERUN}.err
#SBATCH -o ${DIR_LOG}/CLASS4_CORA5_${CONFIG}_${DATERUN}.out
$( sed -e "s/__NBPROC__/$NB_PROC/" $PBS_HEADER )
logfile="/kara/data1/cregnier/log/CORA5/class4_CORA5_${CONFIG}_${DATERUN}.txt"
_EOF_
logfile="/kara/data1/cregnier/log/CORA5/class4_CORA5_${CONFIG}_${DATERUN}.txt"
echo "echo 'kara submits CLASS4 CORA5 $CONFIG $DATERUN' >> $logfile"  >> ${job_script}
echo "cd /home/cregnier/Gitlab/TEP_CLASS4/script " >> ${job_script}
dir_bin='/data/rd_exchange/qualif/anaconda3/envs/env_py38/bin/'
dir_launch='/home/cregnier/Gitlab/TEP_CLASS4/script/'
echo "${dir_bin}python ./TEP_CLASS4_fortran.py --typemod=${TYPEMOD} --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=${SRC} --data=profile --nbproc=${NB_PROC} --daymax=${DAYMAX} >> ${logfile}" >> ${job_script}
echo "Launch script ${job_script}"
qsub ${job_script}
