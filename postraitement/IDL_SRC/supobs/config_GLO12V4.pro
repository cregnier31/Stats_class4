;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'
;; Choix du modele
modele='GLO12V4-light'
;; Choix de la période
year='2019'
trim='0'
zone='T'
dateval='19921101-20141009'
type_data="CORA5.2"
;; Definition des path
dir_mask='/home/cregnier/Gitlab/TEP_CLASS4/postraitement/static/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/GLO12V4/Class4_pics/'
;;fic_out_card=fic_dir+'/Cartes/'
fic_out=fic_dir+'/suivi_rms/CORA5.2/2019/'
fic_out_card=fic_dir+'/Cartes/'+year+'/'
;fic_out=fic_dir+'/suivi_rms/period1/'
fic_out_serie_temp=fic_dir+modele+'/serie_temp/'
dir_stats_MERC='/sortref/opr/diag/GLO12/GLO12V4/stats/CORA5.2/'
dir_stats_MERC2=dir_stats_MERC+'bins_2deg/'
dir_stats_MERC3=dir_stats_MERC+'bins_4deg/'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'
