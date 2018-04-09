;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='YES'
;; Choix du modele
modele='PSY3V3R3'
datetrim='2015_1' 
year='2015'
datetrim='2015_1' 
daterun='20150101'

;; Choix de la période
zone='T'
;; Definition des path
;; Definition des path
dir_mask='/home/qualif/CLASS4/TEP_CLASS4/trunk/postraitement/static/'
fic_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/Class4_pics/
fic_out_card=fic_dir+'/Cartes/GODAE/'
fic_out_skill=fic_out_card+'skill/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY3V3R3/Stats_GODAE/RMS_DIFF/'
dir_stats_MERC2=dir_stats_MERC+'bins2deg/'
dir_stats_MERC2='/naviti/data2/cregnier/Stats_GODAE/RMS_DIFF/PSY3/'
dir_stats_MERC3=dir_stats_MERC2+'/bins4deg/'
fichier=modele+'_rms_diff_bins2deg_R'+daterun+'_profile_votemper.nc'
fichier2=modele+'_rms_diff_bins4deg_R'+daterun+'_profile_votemper.nc'
fichier_SLA=modele+'_rms_diff_bins2deg_R'+daterun+'_SLA_sossheig.nc'
fichier_SST=modele+'_rms_diff_bins2deg_R'+daterun+'_SST_votemper.nc'
fichier_TEMP=modele+'_rms_diff_bins2deg_R'+daterun+'_profile_votemper.nc'
fichier_PSAL=modele+'_rms_diff_bins2deg_R'+daterun+'_profile_vosaline.nc'
fichier_mask='maskbox.nc'
fichier_mask2='mask_bins2deg.nc'
fichier_mask3='mask_bins4deg.nc'
