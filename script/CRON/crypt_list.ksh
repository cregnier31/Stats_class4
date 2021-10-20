#!/bin/ksh
function d2j {
# translate std date to Julian day
# routine Lucas Nouel
   typeset -i day month year tmpmonth tmpyear
   dateD=$1
   day=$(echo $dateD | cut -c7-8)
   month=$(echo $dateD | cut -c5-6)
   year=$( echo $dateD | cut -c1-4)
   ((tmpmonth = 12 * year + month - 3))
   ((tmpyear = tmpmonth / 12))
   val=$(( (734 * tmpmonth + 15) / 24 -  2 * tmpyear + tmpyear/4 - tmpyear/100 + tmpyear/400 + day - 712164 ))
   echo $val
}
function  j2d {
   # translate Julianday to std date
   # routine Lucas Nouel
   typeset -i day month year tmpday centuries
   typeset -Z2 day month
   ((tmpday = $1 + 712164))
   ((centuries = (4 * tmpday - 1) / 146097))
   ((tmpday += centuries - centuries/4))
   ((year = (4 * tmpday - 1) / 1461))
   ((tmpday -= (1461 * year) / 4))
   ((month = (10 * tmpday - 5) / 306))
   ((day = tmpday - (306 * month + 5) / 10))
   ((month += 2))
   ((year += month/12))
   ((month = month % 12 + 1))
   echo $year$month$day
}

PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
CONFIG=$1
CONFIG2=`echo $CONFIG | sed -e 's|Q||g'`
DATE1=$( /bin/date +%Y%m%d --date='last wednesday -7 day')
DATE2=$( /bin/date +%Y%m%d --date='last tuesday')
DATERUN=$( /bin/date +%Y%m%d --date='next wednesday')
if [[ $# -lt 1 ]]
  then
    echo "MODEL???"
    exit 1
fi
juldateini=$( d2j ${DATE1} )
juldatefin=$( d2j ${DATE2} )

flag_ok=${PROGDIR}/log/Class4-${CONFIG}-${DATE1}-${DATE2}-*-OK
nb_flag_ok=`ls ${PROGDIR}/log/Class4-${CONFIG}-${DATE1}-${DATE2}-*OK | wc -l`
if [ $(echo "$nb_flag_ok == 4" | bc) -eq 1 ] ; 
then 
   echo $DATE1 $DATE2
   flag_ok=${PROGDIR}/log/Class4-${CONFIG}-${DATE1}-${DATE2}-crypt-OK
   DIROUT="/utmp/smer/regnierc/CLASS4_GODAE/CLASS4_MERCATOR/PSY4V3R1/current/"
   DIRDECRYPT="${DIROUT}/encrypted/"
   DIRLOG="/home/smer/regnierc/code/TEP_CLASS4/script/CRON/"
   case $CONFIG in
      PSY3V3R1|PSY3V3R3)
           TYPE="orca025"
           ;;
      PSY4QV3R1 | PSY4V3R1)
           TYPE="orca12"
           ;;
       *)
           echo "Type non reconnu"
           exit 0
           ;;
   esac
   
   
   for curday_julian in  $( seq ${juldateini} ${juldatefin} ); do
      for type_data in SST SLA profile aice currents ; do
          curday_gregorian=$( j2d ${curday_julian} )
          echo "DATE : $curday_gregorian"
          DATERUN=$curday_gregorian
          flag_ok=${DIRLOG}Create-CLASS4_${CONFIG}-${DATERUN}-${type_data}-OK
          flag_ftp_ok=${DIRLOG}Put-CLASS4_${CONFIG}-${DATERUN}-${type_data}-OK
          flag_crypt_ok=${DIRLOG}Crypt-CLASS4_${CONFIG}-${DATERUN}-${type_data}-OK
          cd ${DIROUT}
          echo $PWD
	  file=class4_${DATERUN}_${CONFIG2}_${TYPE}_${type_data}.nc
          if [ -f ${file} ]
            then
              mv ${DIROUT}${file} ${DIRDECRYPT}
              cd ${DIRDECRYPT}
              gzip $file 
              file_enc=`echo $file`".gz.enc"
              openssl enc -aes-256-cbc -salt -pass pass:ire15aus6 -in ${file}.gz -out $file_enc
              if [ $? == 0 ]; then
                 /bin/touch ${flag_crypt_ok}
                 echo "Crypt $file OK"
              fi
              ncftpput ftp.usgodae.org pub/incoming/class4 $file_enc 
              if [ $? == 0 ]; then
                 /bin/touch ${flag_ftp_ok}
                 echo "Put $file OK"
              fi
          else
             echo "Fichier manquant $file"
          fi 
   done
   done
else
   exit 1
fi
