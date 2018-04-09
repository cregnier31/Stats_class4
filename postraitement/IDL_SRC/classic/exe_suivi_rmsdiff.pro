;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/param')+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags')$
+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux
@param
@compile
@param_class4
;@config_PSY3V3R1
;@config_PSY3V2R2_RTR
;@config_PSY3V2R2_RTR
;@config_PSY2V4R1_RTR
;@config_PSY2V3R1_RTR
;@config_PSY2V3R1
;@config_PSY3V2R2
;@config_PSY4V1R3
@config_PSY3V3R1
;@config_PSY3V3R2
;@config_PSY2V4R1
;@config_PSY3V3R1_EN3
;@config_PSY2V4R1_EN3
;@config_PSY4V1R3_EN3
;@config_PSY4V1R3
;@config_PSY2V4R2_EN3
;@config_PSY2V4R2
;@config_PSY3QV3R1
;@config_PSY2QV4R2

dirname_out=fic_out
dirin=dir_stats_MERC

; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'

;; Definition des variables
.compile Def_param_bulletin
.compile Def_colors
.compile plot_serietemp_test
.compile plot_serietemp_oper
.compile plot_serietemp_right
.compile tracer_stats_previ

Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$
	valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
	profondeur,profondeur2,profondeur3,profondeur4,liste_zone,$
	liste_zone_PSY2,liste_TEST,liste_zone_PSY2_SHOM

; Compilation & Execution 
.compile tracer_suivi_rmsdiff 
.compile tracer_suivi_rmsdiff_norm 
.compile tracer_suivi_meandiff
.compile tracer_suivi_meandiff_norm
;; choix du type de tracé 
kind='solid_line no_bg grid ' 
clear,titre,units 
;;
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R20 | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R20 | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 

;SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R20110427 | grep '+modele,filelist 
;SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R20110427 | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 

PRINT,filelist,day
print,dir_stats_MERC
CASE modele OF  & $

        'PSY3V2R2': BEGIN & $
         liste_region=strarr(11) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

        'PSY3V3R1': BEGIN & $
         ;liste_region=strarr(14) & $
         ;liste_region(*)=liste_zone(*) & $
         liste_region=strarr(11) & $
         liste_region(*)=liste_zone(*) & $
;	 liste_region=strarr(1) & $ 
;	 liste_region(*)=liste_TEST(*) & $ 
         ENDCASE & $

         'PSY3V3R2': BEGIN & $
         liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

         'PSY3QV3R1': BEGIN & $
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
         ;liste_region=strarr(5) & $
         ;liste_region=liste_zone_PSY2_SHOM & $
         ENDCASE & $

        'PSY2V4R2': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $

        'PSY2QV4R2': BEGIN & $
         liste_region=strarr(7) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $
	
	 'PSY4V1R3': BEGIN & $
         liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

ENDCASE & $
print,liste_region
; tracer_suivi_rmsdiff_norm,modele,fichier,fichier_mask,$        
;   profondeur2,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 
;exit,/NO_CONFIRM
 tracer_suivi_rmsdiff,modele,fichier,fichier_mask,$        
   profondeur2,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER
	
exit,/NO_CONFIRM
; tracer_suivi_meandiff_norm,modele,fichier,fichier_mask,$        
;    profondeur2,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 

exit,/NO_CONFIRM
;tracer_suivi_meandiff,modele,fichier,fichier_mask,$        
;   profondeur2,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 
;  tracer_stats_previ,modele,fichier,fichier_mask,$        
;    profondeur2,variable_name,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 

e²xit, /NO_CONFIRM
