#!/bin/ksh
# Permet de tracer un tableau sur les performances du système
if [[ $# -ne 2 ]]
then
  echo "Error $#  /= 2  ! need 2 parameters Year Quarter"
  echo "Example 2015 2"
exit 1
fi
YEAR=$1
TRIM=$2
case $TRIM in
        1)
        DAY1=${YEAR}0101
        DAY2=${YEAR}0331
        ;;
        2)
        DAY1=${YEAR}0401
        DAY2=${YEAR}0630
        ;;
        3)
        DAY1=${YEAR}0701
        DAY2=${YEAR}0930
        ;;
        4)
        DAY1=${YEAR}1001
        DAY2=${YEAR}1231
        ;;
        *)
        echo "Bad quarter /= 1 2 3 4 "
        exit 13
        ;;
esac
CONFIG=PSY3V3R3
DIR_OUT="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/${CONFIG}/stats/ARMOR/${YEAR}_${TRIM}/stats_ascii/"
[[ ! -d ${DIR_OUT} ]] && mkdir -p ${DIR_OUT}

for variable in TEMP SAL; do

result="${DIR_OUT}/${DAY1}_${DAY2}_stats_${CONFIG}_rms_${variable}.txt"
result2="${DIR_OUT}/${DAY1}_${DAY2}_stats_${CONFIG}_mean_${variable}.txt"
echo " Modèle  $CONFIG RMS DIFF"     > $result
echo " REG   Prof      HID               NOW            FRCST3           FRCST6            PERS           ARV11          LEV09   "  >> $result
echo "----------------------------------------------------------------------"  >> $result
echo " Modèle  $CONFIG MEAN diff"     > $result2
echo " REG   Prof      HID               NOW            FRCST3           FRCST6            PERS           ARV11          LEV09   "  >> $result2
echo "---------------------------------------------------------------------"  >> $result2

for region in ACC ARC GLO IND MED NAT NPA SAT SPA TAT TPA FACADE NORDSEA BALTIC ; do
  for prof in '0-5m' '5-100m' '100-300m' '300-800m' '800-2000m' '2000-5000m' '0-5000m' ; do

       FIC_DIR="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/${CONFIG}/Class4_pics/suivi_rms/${YEAR}_${TRIM}/File_ASCII/"
       fichier="${FIC_DIR}Fic_ASCII_PREVI_rmsval_${variable}_${region}_${CONFIG}_${prof}.txt"
       fichier2="${FIC_DIR}Fic_ASCII_PREVI_meanval_${variable}_${region}_${CONFIG}_${prof}.txt"
       #echo $fichier
       #echo $fichier2
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
         temp_ariv=`awk '{print $7}' $fichier`
         temp2_ariv=`awk '{print $7}' $fichier2`
         temp_lev09=`awk '{print $6}' $fichier`
         temp2_lev09=`awk '{print $6}' $fichier2`
	 echo "TEMP LEV09 $temp_lev09 $temp2_lev09"
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
         sal_ariv=`awk '{print $7}' $fichier`
         sal2_ariv=`awk '{print $7}' $fichier2`
         sal_lev09=`awk '{print $6}' $fichier`
         sal2_lev09=`awk '{print $6}' $fichier2`
	 echo "TEMP SMEV09 $sal_lev09 $sal2_lev09"
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
