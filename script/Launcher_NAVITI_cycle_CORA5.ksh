#!/bin/ksh           
## Laucher for CLASS4 CORA5 in NAVITI
## C.REGNIER December 2016
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." \
        -o "${PROGDIR}" = "${PROGNAME}" \
        -o "${PROGDIR}" = "./." ] \
        && PROGDIR=${PWD}


if [ $# -lt 4 ]; then
    echo "USAGE: ${PROGNAME} <CONFIG> <DATE1><DATE2><NB_PROC> "
    exit 1
fi
CONFIG=$1
DATE1=$2
DATE2=$3
NB_PROC=$4
dir_sub="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script/sub/"
DIR_LOG="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script/log/CORA5/"
### 
DATERUN=${DATE1}
job_script="${dir_sub}/Launch_${DATERUN}_${CONFIG}_nbproc${NB_PROC}.pbs"
PBS_HEADER=${PROGDIR}/envelope_CLASS4_mono.txt
echo ${PROGDIR}/envelope_CLASS4_mono.txt
#PBS_HEADER=${PROGDIR}/envelope_CLASS4_multi.txt
cat > ${job_script} <<_EOF_
#!/bin/ksh
#PBS -N CLASS4_CORA5_${CONFIG}_${DATERUN}
#PBS -e ${DIR_LOG}/CLASS4_CORA5_${CONFIG}_${DATERUN}.err
#PBS -o ${DIR_LOG}/CLASS4_CORA5_${CONFIG}_${DATERUN}.out
$( sed -e "s/__NBPROC__/$NB_PROC/" $PBS_HEADER )
module load ipython/ipython-0.13
module load nco/nco-4.3.2
logfile="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/log/CORA5/class4_CORA5_${CONFIG}_${DATERUN}.txt"
_EOF_
logfile="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/log/CORA5/class4_CORA5_${CONFIG}_${DATERUN}.txt"
echo "echo 'Naviti submits CLASS4 CORA5 $CONFIG $DATERUN' >> $logfile"  >> ${job_script}
echo "cd /home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/script" >> ${job_script}
#echo "python TEP_CLASS4_multiprocess_naviti.py --typemod=pgn --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=CORA5 --data=profile --nbproc=${NB_PROC}"
echo python TEP_CLASS4_multiprocess_naviti_2.py --typemod=allege --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=CORA5 --data=profile --nbproc=${NB_PROC}
echo "python TEP_CLASS4_multiprocess_naviti_2.py --typemod=allege --config=${CONFIG} --date1=${DATE1} --date2=${DATE2} --src=CORA5 --data=profile --nbproc=${NB_PROC}  >> ${logfile}" >> ${job_script}
echo "Launch script ${job_script}"
qsub ${job_script}



