;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@param
@compile
@param_class4

;Chemin du repertoire data de la toolbox
filename='/home/qualif/LIB/LIB_MIT/DATA/'
OPER='NO'

;; Choix du modele
modele='PSY3V2R2'
;modele='PSY2V3R1'

;; Choix de la période
annee='2010'
trimestre='2'
daterun='20100407'

;; Definition des path
dir_mask='/home/qualif/CLASS4/Lecture_Class4_V2.0/static/'
fic_out='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/PSY3V2R2/serie_temp/'+annee+'_'+trimestre+'/'
dir_stats_MERC='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/stats/'+annee+'_'+trimestre+'/'
fichier=modele+'_rms_diff_R'+daterun+'.nc'
fichier_mask='maskbox.nc'
dirname_out=fic_out
dirin=dir_stats_MERC

; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'

;; Definition des profondeurs
;vec_prof=[ 5 , 100 , 500 , 2000 , 5000 , 6000 ]
vec_prof=[ 50 , 100 , 150 , 200 , 250 , 300 , 350 , 400 , 450 , 500 , 600 ]

;; Definition des variables
.compile Def_param_bulletin
.compile Def_colors
.compile plot_xy

;; Chargmement des paramètres globaux
Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$ 
         valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
         profondeur,profondeur2,liste_zone,liste_zone_PSY2,listemodele


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
;   liste_region(0)='GS1' & $
;   liste_region(1)='GS2' & $
;   liste_region(2)='GS3' & $
  ENDIF & $
ENDELSE 

; Compilation & Execution 
.compile tracer_serietemp2_CLASS4_trim

  tracer_serietemp2_CLASS4_trim,modele,fichier,fichier_mask,$        
 profondeur2,vec_prof,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 
 

exit, /NO_CONFIRM
