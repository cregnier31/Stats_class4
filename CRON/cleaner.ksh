#!/bin/ksh
# Nettoyage fichiers sur archive / C.REGNIER Juillet 2013
. /home/smer/smer883/TEP_CLASS4_GODAE/CRON/fonc_util
PROGNAME=${0##*/}
PROGDIR=${0%/*}; [ "${PROGDIR}" = "." ] && PROGDIR=${PWD}
DATERUN=$( /bin/date +%Y%m%d --date='-31 day')
JDATERUN=$( d2j ${DATERUN} )
echo $DATERUN
sort_dir="/W1PSY4/smer/smer883/SORT/DAILY/PSY4Q/psy4qv2r2/"
liste_dirclean="fcst0 fcst1 fcst2 fcst3 fcst4 fcst5 fcst6 nwct"
file_liste="${PROGDIR}/liste_a_effacer.txt"
rm -f ${file_liste}
touch ${file_liste}

for dir in $liste_dirclean ;do
  echo "Repertoire $sort_dir$dir"
  for file in `ls $sort_dir$dir/*.nc`; do
     file_2=$(basename $file)
     #echo "Fichier $file_2"
     day=`echo $file_2 | cut -f3 -d_`
     dayj=$( d2j ${day} )
     if [ ${dayj} -lt ${JDATERUN} ] ;
      then
       echo "fichier a effacer $day $file" >> ${file_liste}
        if [ $? == 0 ]; then
           rm $file
           echo "rm ${file} OK"
           echo "rm OK" >> ${file_liste}
        fi
     fi
  done
done

