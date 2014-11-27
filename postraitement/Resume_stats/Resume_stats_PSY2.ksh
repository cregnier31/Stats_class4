#!/bin/ksh
# Permet de tracer un tableau sur les performances du système
CONFIG=PSY2V4R4
#CONFIG=PSY2V4R1
#DAY1=20110401
DAY1=20120701
DAY2=20120930
DAY1=20121001
DAY2=20121231

DAY1=20130401
DAY2=20130630

TRIM=2
YEAR=2013
file=${YEAR}_${TRIM}

for variable in TEMP SAL; do

result="${file}/${DAY1}_${DAY2}_stats_${CONFIG}_rms_${variable}.txt"
result2="${file}/${DAY1}_${DAY2}_stats_${CONFIG}_mean_${variable}.txt"
echo " Modèle  $CONFIG RMS DIFF"     > $result
echo " REG   Prof      HIND               NOW            FRCST3           FRCST6            PERS           ARV11          LEV09   "  >> $result
echo "----------------------------------------------------------------------"  >> $result
echo " Modèle  $CONFIG MEAN diff"     > $result2
echo " REG   Prof      HIND               NOW            FRCST3           FRCST6            PERS           ARV11          LEV09   "  >> $result2
echo "---------------------------------------------------------------------"  >> $result2

for region in ATL12 FACADE MED NAT NORDSEA TAT ; do
  for prof in '0-5m' '5-100m' '100-300m' '300-800m' '800-2000m' '2000-5000m' '0-5000m' ; do

   #FIC_DIR="/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/${CONFIG}/suivi_rms/${DAY1}_${DAY2}/File_ASCII/"
   FIC_DIR="/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/${CONFIG}/suivi_rms/${file}/File_ASCII/"

       fichier="${FIC_DIR}Fic_ASCII_PREVI${variable}_${region}_${CONFIG}_${prof}.txt"
       fichier2="${FIC_DIR}Fic_ASCII_PREVI_meanval_${variable}_${region}_${CONFIG}_${prof}.txt"
     #  echo $fichier
     #  echo $fichier2
       if [ $variable == "TEMP" ] 
        then 
         temp_hind=`awk '{print $1}' $fichier`
         temp2_hind=`awk '{print $1}' $fichier2`
         temp_ana=`awk '{print $2}' $fichier`
         temp2_ana=`awk '{print $2}' $fichier2`
         temp_fcst3=`awk '{print $3}' $fichier`
         temp2_fcst3=`awk '{print $3}' $fichier2`
         temp_fcst6=`awk '{print $4}' $fichier`
         temp2_fcst6=`awk '{print $4}' $fichier2`
         temp_pers=`awk '{print $5}' $fichier`
         temp2_pers=`awk '{print $5}' $fichier2`
         temp_lev09=`awk '{print $6}' $fichier`
         temp2_lev09=`awk '{print $6}' $fichier2`
         temp_ariv=`awk '{print $7}' $fichier`
        temp2_ariv=`awk '{print $7}' $fichier2`
       else
         sal_hind=`awk '{print $1}' $fichier`
         sal2_hind=`awk '{print $1}' $fichier2`
         sal_ana=`awk '{print $2}' $fichier`
         sal2_ana=`awk '{print $2}' $fichier2`
         sal_fcst3=`awk '{print $3}' $fichier`
         sal2_fcst3=`awk '{print $3}' $fichier2`
         sal_fcst6=`awk '{print $4}' $fichier`
         sal2_fcst6=`awk '{print $4}' $fichier2`
         sal_pers=`awk '{print $5}' $fichier`
         sal2_pers=`awk '{print $5}' $fichier2`
         sal_lev09=`awk '{print $6}' $fichier`
         sal2_lev09=`awk '{print $6}' $fichier2`
         sal_ariv=`awk '{print $7}' $fichier`
         sal2_ariv=`awk '{print $7}' $fichier2`
       fi 
       if [ $variable == "TEMP" ] 
        then 
           echo "$region  , $prof  ,  $temp_hind   ,   $temp_ana  ,   $temp_fcst3  ,   $temp_fcst6  ,   $temp_pers   ,  $temp_ariv   ,   $temp_lev09 "  >> $result
           echo "$region  , $prof  ,  $temp2_hind   ,   $temp2_ana  ,   $temp2_fcst3  ,   $temp2_fcst6  ,   $temp2_pers   ,  $temp2_ariv   ,   $temp2_lev09 "  >> $result2
       else
           echo "$region  , $prof  ,  $sal_hind  , $sal_ana  ,   $sal_fcst3  ,   $sal_fcst6  ,   $sal_pers   ,  $sal_ariv  ,  $sal_lev09"  >> $result
           echo "$region  , $prof  ,  $sal2_hind  , $sal2_ana  ,   $sal2_fcst3  ,   $sal2_fcst6  ,   $sal2_pers   ,  $sal2_ariv  ,  $sal2_lev09"  >>  $result2
       fi
       print "REGION $region Profondeur $prof  Variable $variable"
    done
   echo "--------------------------------------------------------------------------" >> $result
   echo "--------------------------------------------------------------------------" >> $result2
   done 
done   
