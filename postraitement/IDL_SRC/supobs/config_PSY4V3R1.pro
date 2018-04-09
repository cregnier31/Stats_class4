;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'
;; Choix du modele
modele='PSY4V3R1'
;; Choix de la période
;year='2007-2016'
year='2015'
zone='T'
;zone='C'
;zone='MED'
;zone='A'
;; Definition des path
dir_mask='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/static/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/Class4_pics/'
fic_out_card=fic_dir+'/Cartes/'+year+'/'
fic_out_MYO2=fic_dir+'Stats_MYO2/'+year+'/'
fic_out=fic_dir+'/suivi_rms/'+year+'/'
fic_out_serie_temp=fic_dir+'/serie_temp/'+year+'/'
dr_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/ARMOR/'+year+'/'
dir_stats_MERC="/sortref/calval/DATA_COLOCATIONS/T_S_data_new/"+modele+"/data/RUN12/stats/"
dir_stats_MERC="/naviti/data2/cregnier/PSY4V3R1/data/RUN12/stats/"
dir_stats_MERC2=dir_stats_MERC+'bins_2deg/'
dir_stats_MERC3=dir_stats_MERC+'bins_4deg_new/'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'


