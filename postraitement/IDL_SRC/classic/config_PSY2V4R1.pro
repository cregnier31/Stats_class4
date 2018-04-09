;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
;OPER='NO'
OPER='YES'
;; Choix du modele
modele='PSY2V4R1'
trim='4'
year='2010'
;; Choix de la période
daterun='20101006'
zone='A'
;; Definition des path
dir_mask='/home/qualif/CLASS4/Lecture_Class4_V2.0/static/'
fic_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/'
fic_out_card=fic_dir+modele+'/Cartes/'+year+'_'+trim+'/'
fic_out=fic_dir+modele+'/suivi_rms/'+year+'_'+trim+'/'
fic_out_serie_temp=fic_dir+modele+'/serie_temp/'+year+'_'+trim+'/'
fic_out_comp='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY2/'+year+'_'+trim+'/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/'+year+'_'+trim+'/'
dir_stats_MERC2=dir_stats_MERC+'bins_2deg/'
fichier=modele+'_rms_diff_R'+daterun+'.nc'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'



