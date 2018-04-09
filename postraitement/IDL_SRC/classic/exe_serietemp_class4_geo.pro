;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/cregnier/IDL/Toolbox_11_2007')+':'+expand_path('+/home/cregnier/IDL/DATA')+':'+expand_path('/home/cregnier/IDL/new')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@param
@param_gauges
@compile
@compile_new
;Chemin du repertoire data de la toolbox
filename='/home/cregnier/IDL/DATA/'


;; Choix du modele
;modele='PSY3V2R2'
modele='PSY2V3R1'
;; Definition des path
dir_mask='/home/cregnier/DEV/Dev_corio/Lecture_Class4/stats/MASK/'
fic_out='/data/rd_exchange/cregnier/CLASS4_test/Images/'
;;dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_glorys/stats/'
;;dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4/stats/new_trait/'
;dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_test/STATS/test_pers6j_old_colloc/'
;dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_test/STATS/test_pers6j_new_colloc/'
;dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_test/STATS/oper/all-11/'
;dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_test/STATS/new_stats/'
;dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_test/STATS/new_stats_winterp/'
;OPER='YES'
OPER='NO'
IF ( OPER  eq "YES" ) THEN BEGIN & $
  PRINT , "YES" & $
  dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_test/STATS/stats_'+modele+'_oper/' & $
 endif else begin  & $
IF ( OPER eq "NO" ) THEN BEGIN & $
  dir_stats_MERC='/data/rd_exchange/cregnier/CLASS4_test/STATS/stats_'+modele+'/' & $
 ENDIF & $
ENDELSE 
fichier=modele+'_rms_diff_R20091111.nc'
;fichier='PSY3V2R2_rms_diff_R20091223.nc'
fichier_mask='maskbox.nc'
dirname_out=fic_out
dirin=dir_stats_MERC

tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
;; Definition des variables

Def_param_bulletin
;;COMMON param_CLASS4,variable_name,valeurs_cmax2,valeurs_cmax2_sal,profondeur,liste_zone,listemodele,profondeur2
COMMON param_CLASS4,variable_name,valeurs_cmax,$ 
	valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,listemodele

; Compilation & Execution 
.compile tracer_serietemp_CLASS4_trim 
 	
;; choix du type de tracé 
kind='solid_line no_bg grid ' 
clear,titre,units 
;;
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
PRINT,filelist,day
IF ( modele eq "PSY3V2R2" ) THEN BEGIN & $
   liste_region=strarr(11) & $
   liste_region(*)=liste_zone(*) & $
  endif else begin  & $
  IF ( modele eq 'PSY2V3R1') THEN BEGIN & $
   liste_region=strarr(3) & $
   liste_region=liste_zone_PSY2 & $
  ENDIF & $
ENDELSE                   

  PRINT ,"dir_STAT :: ",dir_stats_MERC
  tracer_serietemp_CLASS4_trim,modele,fichier,fichier_mask,$        
    profondeur2,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 

exit, /NO_CONFIRM
