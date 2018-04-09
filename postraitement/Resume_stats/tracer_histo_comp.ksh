#!/bin/ksh
if [ $# -lt 5 ]
then
  echo "Nb d'argument incorrects :: "
  echo "Necessite 8 arguments :: "
  echo " Config "
  echo " Config2 "
  echo " Config3 "
  echo " Annee "
  echo " Trimestre "
  exit 0
fi

config=$1
config2=$2
config3=$3
YEAR=$4
TRIM=$5
case $TRIM in
        1)
        QUART='JFM'
        DATE1=${YEAR}0101
        DATE2=${YEAR}0331
        MONTH='Feb'
        MONTH1='01'
        MONTH2='02'
        MONTH3='03'
        ;;
        2)
        QUART='AMJ'
        DATE1=${YEAR}0401
        DATE2=${YEAR}0630
        MONTH='Jun'
        MONTH1='04'
        MONTH2='05'
        MONTH3='06'
        ;;
        3)
        QUART='JAS'
        DATE1=${YEAR}0701
        DATE2=${YEAR}0930
        MONTH='Sep'
        MONTH1='07'
        MONTH2='08'
        MONTH3='09'
        ;;
        4)
        QUART='OND'
        DATE1=${YEAR}1001
        DATE2=${YEAR}1231
        MONTH='Dec'
        MONTH1='10'
        MONTH2='11'
        MONTH3='12'
	;;
	*)
	  echo "TRIM not found"
	  exit
	;;
esac
liste_region="BALTIC NORDSEA FACADE ACC ARC GLO IND MED NAT NPA SAT SPA TAT TPA"
DIR_STATS1="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/${config}/stats/ARMOR/${YEAR}_${TRIM}/stats_ascii/"
DIR_STATS2="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/${config2}/stats/ARMOR/${YEAR}_${TRIM}/stats_ascii/"
DIR_STATS3="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/${config3}/stats/ARMOR/${YEAR}_${TRIM}/stats_ascii/"
DIR_OUT="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/Histogrammes/${YEAR}_${TRIM}/"
[[ ! -d ${DIR_OUT} ]] && mkdir -p ${DIR_OUT}

day1=${DATE1}
day2=${DATE2}
if [ ! -d ${DIR_OUT} ]
 then 
 mkdir -p ${DIR_OUT}
fi
for stats in mean rms ; do
 for var in SAL TEMP; do
   for region in $liste_region ; do
     echo "Region variable : $region $var" 
     file="${DIR_STATS1}/${day1}_${day2}_stats_${config}_${stats}_${var}.txt"
     file2="${DIR_STATS2}/${day1}_${day2}_stats_${config2}_${stats}_${var}.txt"
     file3="${DIR_STATS3}/${day1}_${day2}_stats_${config3}_${stats}_${var}.txt"
     file_out="${DIR_OUT}/${var}_${stats}_${region}_intercomp.gif"
     echo " reset" > file_gnu 
     echo "set term gif medium size 479,450" >> file_gnu 
     echo "set out '${file_out}'" >> file_gnu
     echo "set key box" >> file_gnu
     echo "set key out right center  vertical samplen 2 spacing 8 height 1 width 2 " >> file_gnu
     echo "set style data histogram" >> file_gnu
     echo "set style histogram cluster gap 3">> file_gnu
     echo "set style fill solid border -1" >> file_gnu
     echo "set boxwidth 1">> file_gnu 
     echo "set xtics rotate by 90 right ">> file_gnu
     echo "set ytics rotate by 90 center">> file_gnu
     echo "set ylabel '${stats} ${var} ${region} ${QUART}${YEAR}' offset 2.5">> file_gnu
     echo "set xlabel ' '">> file_gnu
#     echo "set size 0.8, 1" >> file_gnu
      echo $file
     if  [  "$region" = "BALTIC" -o "$region" = "MED" -o "$region" = "NAT" -o "$region" = "TAT"  -o "$region" = "NORDSEA" -o "$region" = "FACADE" ] 
        then
         cat $file | grep $region |  awk '{print $3,$5}' > test1.txt
         cat $file2 | grep $region |  awk '{print $5}' > test2.txt
         cat $file3 | grep $region |  awk '{print $5}' > test3.txt
         cat $file  | grep $region |  awk '{print $9}' > test4.txt
	 paste test1.txt test2.txt test3.txt test4.txt > test.txt	
	 name1=`echo $config | cut -c1-4` 
	 name2=`echo $config2 | cut -c1-4` 
	 name3=`echo $config3 | cut -c1-4` 
         echo "set label 2 '$name1' at graph 1.08, 0.64 left rotate by 90">> file_gnu
         echo "set label 3 '$name2' at graph 1.08, 0.52 left rotate by 90">> file_gnu
         echo "set label 4 '$name3' at graph 1.08, 0.40 left rotate by 90">> file_gnu
         echo "set label 5 'LEV09' at graph 1.08, 0.28 left rotate by 90">> file_gnu
	 ## 4 fichier x=0.3 0.42 0.52 0.63
         echo "p 'test.txt' u 2 title '  ' lc rgb'blue', '' u 3 title ' ' lc rgb'red', '' u 4 title ' ' lc rgb'yellow', '' u 5 title ' ' lc rgb'gray','' u 0:(0):xticlabel(1) w l title ''">>file_gnu
	 echo "Region $region"
   else
       cat $file | grep $region |  awk '{print $3,$5}' > test1.txt
       cat $file2 | grep $region |  awk '{print $5,$17}' > test2.txt
       paste test1.txt test2.txt > test.txt
       name1=`echo $config | cut -c1-4`
       name2=`echo $config2 | cut -c1-4`
       echo "set label 2 '$name1' at graph 1.08, 0.58 left rotate by 90">> file_gnu
       echo "set label 3 '$name2' at graph 1.08, 0.46 left rotate by 90">> file_gnu
       echo "set label 4 'LEV09' at graph 1.08, 0.33 left rotate by 90">> file_gnu
       echo "p 'test.txt' u 2 title '  ' lc rgb'blue', '' u 3 title ' ' lc rgb'red', '' u 4 title ' ' lc rgb'gray', '' u 0:(0):xticlabel(1) w l title ''">>file_gnu
    fi 
     gnuplot file_gnu
     convert -rotate 90 ${file_out} ${file_out}
     echo "Stats $stats Var $var region $region  OK"
   done
  done
done
rm -f file_gnu
rm -f  test*.txt
