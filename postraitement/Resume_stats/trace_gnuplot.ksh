#!/bin/ksh

config=T321
liste_region="ACC ARC GLO IND MED NAT NPA SAT SPA TAT TPA FACADE NORDSEA"
DIR_IN="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/test/2009/Class4_pics/T321/Resumé_stats/"
for stats in mean rms ; do
 for var in SAL TEMP; do
   for region in $liste_region ; do
 
     file="${DIR_IN}/stats_${config}_${stats}_${var}.txt"
     echo "Fichier $file"
     file_out=${DIR_IN}/${var}_${stats}_${region}_${config}.gif
     cat $file | grep $region |  awk '{print $3,$5,$7}' > test.txt
     echo " reset" > file_gnu 
     echo "set term gif " >> file_gnu 
     echo "set out '${file_out}'" >> file_gnu
     echo "set key out right center  vertical samplen 2 spacing 8 height 1 width 2 " >> file_gnu
     echo "set style data histogram" >> file_gnu
     echo "set style histogram cluster gap 3">> file_gnu
     echo "set style fill solid border -1" >> file_gnu
     echo "set boxwidth 1">> file_gnu 
     echo "set xtic rotate by 90 ">> file_gnu
     echo "set ytic rotate by 90 ">> file_gnu
     echo "set ylabel '${stats} difference (Obs - Mod ) ${var} ${region} ${config} ' offset -2.5">> file_gnu
     echo "set xlabel ' '">> file_gnu
     echo "set size 0.8, 1" >> file_gnu
     echo "set label 2 'HIND' at graph 1.08, 0.52 left rotate by 90">> file_gnu
     echo "set label 3 'LEV09' at graph 1.08, 0.40 left rotate by 90">> file_gnu
     echo "p 'test.txt' u 2 title '  ', '' u 3 title ' ','' u 0:(0):xticlabel(1) w l title ''">>file_gnu
     gnuplot file_gnu
     convert -rotate 90 ${file_out} ${file_out}
     echo "Stats $stats Difference (Obs - Mod )  Var $var region $region  OK"
   done
  done
done

rm file_gnu test.txt
