;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='YES'
;; Choix du modele
modele='PSY4V2R2'
;; Choix de la période
year='2014'
trim='3'
zone='T'
;zone='C'
;zone='MED'
;zone='A'
;; Definition des path
dir_mask='/home/qualif/CLASS4/TEP_CLASS4/trunk/postraitement/static/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/Class4_pics/
fic_out_card=fic_dir+'/Cartes/'+year+'_'+trim+'/'
fic_out_MYO2=fic_dir+'Stats_MYO2/'+year+'/'+year+'_'+trim+'/'
fic_out_card=fic_dir+'/Cartes/'+year+'/'
fic_out=fic_dir+'/suivi_rms/'+year+'_'+trim+'/'
;fic_out=fic_dir+'/suivi_rms/all/'
fic_out_serie_temp=fic_dir+'/serie_temp/'+year+'_'+trim+'/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/ARMOR/'+year+'_'+trim+'/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/ARMOR/all/'
dir_stats_MERC2=dir_stats_MERC+'bins_2deg_new/'
dir_stats_MERC3=dir_stats_MERC+'bins_4deg_new/'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'


