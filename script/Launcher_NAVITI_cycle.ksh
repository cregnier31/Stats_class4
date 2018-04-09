#!/bin/ksh           
## Laucher for CLASS4 seaice in NAVITI
## C.REGNIER March 2015
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}


if [ $# -lt 3 ]; then
    echo "USAGE: ${PROGNAME} <CONFIG> <DATERUN> <NB_PROC> "
    exit 1
fi
CONFIG=$1
DATERUN=$2
NB_PROC=$3
#DATERUN=$( /bin/date +%Y%m%d --date='-15 day')
#DATERUN=$( /bin/date +%Y%m%d --date='-15 day')
dir_sub="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script/sub/"
DIR_LOG="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script/log/"
### 
job_script="${dir_sub}/Launch_${DATERUN}_${CONFIG}_nbproc${NB_PROC}.pbs"
PBS_HEADER=${PROGDIR}/envelope_CLASS4_mono.txt
echo ${PROGDIR}/envelope_CLASS4_mono.txt
#PBS_HEADER=${PROGDIR}/envelope_CLASS4_multi.txt
cat > ${job_script} <<_EOF_
#!/bin/ksh
#PBS -N CLASS4_AICE_${CONFIG}_${DATERUN}
#PBS -e ${DIR_LOG}/CLASS4_AICE_${CONFIG}_${DATERUN}.err
#PBS -o ${DIR_LOG}/CLASS4_AICE_${CONFIG}_${DATERUN}.out
$( sed -e "s/__NBPROC__/$NB_PROC/" $PBS_HEADER )
module load ipython/ipython-0.13
module load nco/nco-4.3.2
logfile="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/log/class4_aice_${DATERUN}.txt"
_EOF_
logfile="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/log/class4_aice_${DATERUN}.txt"
echo "echo 'Naviti submits CLASS4 aice $CONFIG $DATERUN' >> $logfile"  >> ${job_script}
echo "cd /home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script" >> ${job_script}
echo "python TEP_CLASS4_aice.py --config=${CONFIG} --daterun=${DATERUN} --nbdate=1 --delta=0 --src=GODAE --data=aice --typemod=pgn >> ${logfile}" >> ${job_script}
#echo "python TEP_CLASS4_multiprocess_naviti_test.py --config=${CONFIG} --nbproc=${NB_PROC} --daterun=${DATERUN} --nbdate=1 --delta=0 --src=GODAE --data=aice >> ${logfile}" >> ${job_script}
echo "Launch script ${job_script}"
qsub ${job_script}



