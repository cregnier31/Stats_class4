#!/bin/ksh
if [ $# -lt 3 ]
then
  echo "Nb d'argument incorrects :: "
  echo "Necessite 3 arguments :: "
  echo " Config "
  echo " Annee "
  echo " Trimestre "
  exit 0
fi

CONFIG=$1
YEAR=$2
TRIM=$3

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
        echo "Bad quarter /= 1 2 3 4 "
        exit 13
        ;;
esac
case ${CONFIG} in
     PSY2V4R2 | PSY2V4R4 )
      liste_region="ATL12 FACADE MED NAT NORDSEA TAT"
      ;;
     PSY3V3R1 | PSY3V3R3 | PSY4V1R3 | PSY4V2R2 )
      liste_region="ACC ARC GLO IND MED NAT NPA SAT SPA TAT TPA FACADE NORDSEA"
      ;;
     *)
      echo "Modele non reconnu "
      exit 13
     ;;
esac        	
day1=${DATE1}
day2=${DATE2}
for stats in mean rms ; do
 for var in SAL TEMP; do
   for region in $liste_region ; do
   #for region in IND ; do
 
     file="${YEAR}_${TRIM}/${day1}_${day2}_stats_${CONFIG}_${stats}_${var}.txt"
     echo "Fichier $file"
     file_out="${YEAR}_${TRIM}/${var}_${stats}_${region}_${CONFIG}.gif"
     case ${CONFIG} in
       PSY2V4R4 | PSY3V3R3 )
          cat $file | grep $region |  awk '{print $3,$5,$7,$9,$11,$13,$17}' > test.txt
          echo " reset" > file_gnu 
	  echo "set term gif medium size 479,450" >> file_gnu 
          echo "set out '${file_out}'" >> file_gnu
          echo "set key box" >> file_gnu
          echo "set key out right center vertical samplen 2 spacing 8 height 1 width 2 " >> file_gnu
          echo "set style data histogram" >> file_gnu
          echo "set style histogram cluster gap 3">> file_gnu
          echo "set style fill solid border -1" >> file_gnu
          echo "set boxwidth 1">> file_gnu 
	  echo "set xtics rotate by 90 right font ',8'" >> file_gnu
	  echo "set ytics rotate by 90 center">> file_gnu
          echo "set ylabel '${stats} difference (Obs - Mod ) ${var} ${region} ${CONFIG} ' offset 2.5 ">> file_gnu
          echo "set xlabel ' '">> file_gnu
          echo "set label 6 'HIND' at graph 1.08, 0.22 left rotate by 90" >> file_gnu
          echo "set label 5 'NOW' at graph 1.08, 0.35 left rotate by 90" >> file_gnu
          echo "set label 4 'F3' at graph 1.08, 0.48 left rotate by 90" >> file_gnu
          echo "set label 3 'F6' at graph 1.08, 0.59 left rotate by 90" >> file_gnu
          echo "set label 2 'LEV09' at graph 1.08, 0.68 left rotate by 90" >> file_gnu
          echo "p 'test.txt'  u 7 title '  ' lc rgb'gray' , '' u 5 title ' ' lc rgb'red', '' u 4 title ' ' lc rgb'orange', '' u 3 title ' ' lc rgb'yellow' , '' u 2 title ' ' lc rgb'green','' u 0:(0):xticlabel(1) w l title ''">> file_gnu
       ;;
       PSY4V2R2 )
	  cat $file | grep $region |  awk '{print $3,$5,$7,$9}' > test.txt
          echo " reset" > file_gnu
	  echo "set term gif medium size 479,450" >> file_gnu 
          echo "set out '${file_out}'" >> file_gnu
          echo "set key box" >> file_gnu
          echo "set key out right center  vertical samplen 2 spacing 8 height 1 width 2 " >> file_gnu
          echo "set style data histogram" >> file_gnu
          echo "set style histogram cluster gap 3">> file_gnu
          echo "set style fill solid border -1" >> file_gnu
          echo "set boxwidth 1">> file_gnu
	  echo "set xtics rotate by 90 right font ',8'" >> file_gnu
	  echo "set ytics rotate by 90 center">> file_gnu
          echo "set ylabel '${stats} difference (Obs - Mod ) ${var} ${region} ${CONFIG} ' offset 2.5">> file_gnu
          echo "set xlabel ' '">> file_gnu
          echo "set label 4 'HIND' at graph 1.08, 0.34 left rotate by 90" >> file_gnu
          echo "set label 3 'NOW' at graph 1.08, 0.47 left rotate by 90" >> file_gnu
          echo "set label 2 'LEV09' at graph 1.08, 0.56 left rotate by 90" >> file_gnu
          echo "p 'test.txt' u 4 title '  ' lc rgb'gray', '' u 3 title ' ' lc rgb'yellow', '' u 2 title ' ' lc rgb'green','' u 0:(0):xticlabel(1) w l title ''">>file_gnu
     ;;
     esac
     gnuplot file_gnu
     convert -rotate 90 ${file_out} ${file_out}
     echo "Stats $stats Difference (Obs - Mod )  Var $var region $region  OK"
   done
  done
done
rm -f file_gnu test.txt
