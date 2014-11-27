#!/bin/ksh
# Permet de tracer un tableau sur les performances du système
CONFIG=T321
YEAR=2009

file="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/test/2009/Class4_pics/T321/Resumé_stats/"
if [ ! -f $file ] 
 then
 mkdir -p $file
fi

FIC_DIR="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/test/2009/Class4_pics/T321/suivi_rms/File_ASCII/"

for variable in TEMP SAL; do

result="${file}/stats_${CONFIG}_rms_${variable}.txt"
result2="${file}/stats_${CONFIG}_mean_${variable}.txt"
echo " Modèle  $CONFIG RMS DIFF"     > $result
echo " REG   Prof      HID     LEV09  "  >> $result
echo "----------------------------------------------------------------------"  >> $result
echo " Modèle  $CONFIG MEAN diff"     > $result2
echo " REG    Prof     HID      LEV09  " >> $result2
echo "---------------------------------------------------------------------"  >> $result2

for region in ACC ARC GLO IND MED NAT NPA SAT SPA TAT TPA FACADE NORDSEA ; do
  for prof in '0-5m' '5-100m' '100-300m' '300-800m' '800-2000m' '2000-5000m' '0-5000m' ; do

       fichier="${FIC_DIR}Fic_ASCII_PREVI${variable}_${region}_${CONFIG}_${prof}.txt"
       fichier2="${FIC_DIR}Fic_ASCII_PREVI_meanval_${variable}_${region}_${CONFIG}_${prof}.txt"
     #  echo $fichier
     #  echo $fichier2
       if [ $variable == "TEMP" ] 
        then 
         temp_hind=`awk '{print $1}' $fichier`
         temp2_hind=`awk '{print $1}' $fichier2`
         temp_lev09=`awk '{print $2}' $fichier`
        temp2_lev09=`awk '{print $2}' $fichier2`
       else
         sal_hind=`awk '{print $1}' $fichier`
         sal2_hind=`awk '{print $1}' $fichier2`
         sal_lev09=`awk '{print $2}' $fichier`
         sal2_lev09=`awk '{print $2}' $fichier2`
       fi 
       if [ $variable == "TEMP" ] 
        then 
           echo "$region  , $prof  ,  $temp_hind  ,  $temp_lev09 "  >> $result
           echo "$region  , $prof  ,  $temp2_hind   ,  $temp2_lev09 "  >> $result2
       else
           echo "$region  , $prof  ,  $sal_hind  ,  $sal_lev09"  >> $result
           echo "$region  , $prof  ,  $sal2_hind  ,  $sal2_lev09"  >>  $result2
       fi
       print "REGION $region Profondeur $prof  Variable $variable"
    done
   echo "--------------------------------------------------------------------------" >> $result
   echo "--------------------------------------------------------------------------" >> $result2
   done 
done   
