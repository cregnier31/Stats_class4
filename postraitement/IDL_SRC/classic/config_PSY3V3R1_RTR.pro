;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'
;; Choix du modele
modele='PSY3V3R1'
zone='T'
;; Choix de la période
annee='2007-2010'
daterun='20070103'
;; Definition des path
type_RTR="RTR"
dir_mask='/home/qualif/CLASS4/Lecture_Class4_V2.0/static/'
fic_out='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'+modele+'/'
;fic_out='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'+modele+'/rejeu_RTR/'
fic_out_serie_temp='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/Serie_temp_MyO/'
fic_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'
fic_out_card=fic_dir+modele+'/'+type_RTR+'/Cartes/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/RTR/'
;dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/RTR_rejeu/'
fichier=modele+'_rms_diff_R'+daterun+'.nc'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'



;fic_out='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'+modele+'/'+type_RTR+'/'
;fic_out_RTR1=fic_dir+modele+'/RTR1/'
;fic_out_RTR2bis='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'+modele+'/RTR2bis/'
;fic_out_RTR=fic_out_RTR2bis
;dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/'+type_RTR+'/'
