;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'
;; Choix du modele
modele='T321'
daterun='20090107'
year='2009'
;; Choix de la période
zone='T'
;; Definition des path
dir_mask='/home/qualif/CLASS4/Lecture_Class4_V2.0/static/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/test/2009/Class4_pics/'
fic_out_card=fic_dir+modele+'/Cartes/'
fic_out=fic_dir+modele+'/suivi_rms/'
fic_out_skill=fic_out_card+'skill_scores/'
fic_out_serie_temp=fic_dir+modele+'/serie_temp/'
fic_out_comp='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY3/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/test/'+year+'/'
dir_stats_MERC2=dir_stats_MERC+'bins_2deg/'
dir_stats_MERC3=dir_stats_MERC+'bins_4deg/'
fichier=modele+'_rms_diff_R'+daterun+'.nc'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'
