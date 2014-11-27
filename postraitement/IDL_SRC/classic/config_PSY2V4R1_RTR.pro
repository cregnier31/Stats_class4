;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'
;; Choix du modele
modele='PSY2V4R1'
;; Choix de la période
daterun='20070103'
zone='A'
;; Definition des path
dir_mask='/home/qualif/CLASS4/Lecture_Class4_V2.0/static/'
;; fichiers stats
;;dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/RTR/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/RTR_rejeu/'
dir_stats_MERC2=dir_stats_MERC+'bins_2deg/'

;; Sorties idl
fic_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'
;;fic_out=fic_dir+modele+'
fic_out=fic_dir+modele+'/rejeu_RTR/'
fic_out_card=fic_out2+'Cartes/'
fic_out_serie_temp=fic_dir+'Serie_temp_MyO/'

fichier=modele+'_rms_diff_R'+daterun+'.nc'

fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'



