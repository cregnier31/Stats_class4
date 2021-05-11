;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'
;; Choix du modele
modele='GLORYS12V1'
;; Choix de la période
zone='T'
dateval='19930101-20161231'
;; Definition des path
dir_mask='/home/qualif/CLASS4/TEP_CLASS4/trunk/postraitement/static/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/Class4_pics/'
;;fic_out_card=fic_dir+'/Cartes/'
fic_out=fic_dir+'/suivi_rms/CORA5/'
;fic_out=fic_dir+'/suivi_rms/period1/'
fic_out_serie_temp=fic_dir+modele+'/serie_temp/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/ALLEGES_CORA5/'
dir_stats_MERC2=dir_stats_MERC+'bins_2deg/'
dir_stats_MERC3=dir_stats_MERC+'bins_4deg/'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'
