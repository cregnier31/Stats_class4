;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'
;; Choix du modele
modele='GLORYS12V1'
;; Choix de la période
zone='T'
zone='ARC'
year='2011'
TRIM='0'
;type_data="CORA4.1"
type_data="CORA5"
;; Definition des path
dir_mask='/home/qualif/CLASS4/TEP_CLASS4/trunk/postraitement/static/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/Class4_pics/'
fic_out_card=fic_dir+'/Cartes/'+type_data+'/'+zone+'/'
;fic_out=fic_dir+'/suivi_rms/'
fic_out=fic_dir+'/suivi_rms/'+type_data+'/'
;fic_out=fic_dir+'/suivi_rms/period1/'
fic_out_serie_temp=fic_dir+modele+'/serie_temp/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/ALLEGES_'+type_data+'/'
;dir_stats_MERC='/naviti/data5/cregnier/GLORYS12V1/stats/'
;dir_stats_MERC='/naviti/data5/cregnier/GLORYS12V1/stats_CORA4/'
dir_stats_MERC2=dir_stats_MERC+'bins_2deg/'
dir_stats_MERC3=dir_stats_MERC+'bins_4deg/'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'
