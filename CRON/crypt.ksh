#!/bin/ksh
DATERUN=$( /bin/date +%Y%m%d --date='-15 day')
DATERUN=$( /bin/date +%Y%m%d --date='-12 day')
echo $DATERUN
DIROUT="/W1PSY4/smer/smer883/CLASS4_MERCATOR/OUTPUT/"
DIRDECRYPT="${DIROUT}/encrypted/"
DIRLOG="/home/smer/smer883/TEP_CLASS4_GODAE/CRON/log/"
TYPE=orca025
CONFIG=$1
case $CONFIG in
   PSY3V3R1|PSY3V3R3)
        TYPE="orca025"
        ;;
   PSY4V2R2)
        TYPE="orca12"
        ;;
    *)
        echo "Type non reconnu"
        exit 0
        ;;
esac

for type_data in SST SLA profile ; do
#for type_data in profile ; do
#for type_data in SLA; do
  flag_ok=${DIRLOG}Create-CLASS4_${CONFIG}-${DATERUN}-${type_data}-OK
  flag_ftp_ok=${DIRLOG}Put-CLASS4_${CONFIG}-${DATERUN}-${type_data}-OK
  flag_crypt_ok=${DIRLOG}Crypt-CLASS4_${CONFIG}-${DATERUN}-${type_data}-OK
  echo $flag_ok
  if [  -f ${flag_ok} ]
   then
    cd ${DIROUT}
    file=class4_${DATERUN}_${CONFIG}_${TYPE}_${type_data}.nc
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
  else
    echo "Flag manquant ${flag_ok}"
  fi
done
