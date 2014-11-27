;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@param
@compile
@param_class4
;@config_PSY3V3R1
;@config_PSY2V4R1
;@config_PSY2V3R1
@config_PSY3V3R1
;@config_PSY2V4R1
;@config_PSY2V4R1_EN3
@config_PSY3V3R1_EN3
;@config_PSY2V4R1
@config_PSY4V1R3
@config_PSY4V1R3_EN3
@config_PSY2V4R2
@config_PSY2V4R2_EN3

; Definition des paths
dirname_out=fic_out_serie_temp
dirin=dir_stats_MERC

tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
;; Definition des profondeurs
;vec_prof=[ 5 , 100 , 500 , 2000 , 5000 , 6000 ]
vec_prof=[ 50 , 100 , 150 , 200 , 250 , 300 , 350 , 400 , 450 , 500 , 600 ]

;; Definition des variables
.compile Def_param_bulletin
.compile Def_colors
Def_param_bulletin
COMMON param_CLASS4,variable_name,valeurs_cmax,$
       valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
       profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,listemodele,liste_zone_GLOMyo

; Compilation & Execution 
print,"Tracer serie temp" 
.compile tracer_multiserietemp_CLASS4_trim
;; choix du type de tracé 
kind='grid solid_line no_bg grid ' 
clear,titre,units 
;;
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
PRINT,filelist,day
CASE modele OF  & $

        'PSY3V2R2': BEGIN & $
         liste_region=strarr(11) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

        'PSY3V3R1': BEGIN & $
         print ,'Modele :: ',modele & $
         ;liste_region=strarr(8)   & $ 
         liste_region=strarr(14) & $
         ;liste_region(*)=liste_zone_GLOMyo(*) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

        'PSY4V1R3': BEGIN & $
         liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

        'PSY2V3R1': BEGIN & $
         liste_region=strarr(3) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $

        'PSY2V4R1': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ;liste_region=strarr(1) & $
         ;liste_region='TAT' & $
         ENDCASE & $

        'PSY2V4R2': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $

ENDCASE & $

  tracer_multiserietemp_CLASS4_trim,modele,fichier,fichier_mask,$        
     profondeur2,vec_prof,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 
 

exit, /NO_CONFIRM
