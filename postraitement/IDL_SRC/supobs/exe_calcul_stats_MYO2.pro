;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4 afin de créer des fichiers netcdf de Stats pour MyOcean2
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Septembre 2011 Ajout de supobs
; C.REGNIER  Janvier   2012 Ecriture des stats MyO2 avec les bons formats
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/param')+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags')$
+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux
@param
@param_class4
@compile

;@config_PSY3V3R1_oper
;@config_PSY4V1R3_oper
;@config_PSY2V4R2_oper

dirname_out=fic_out_MYO2
dirin=dir_stats_MERC

print, dirin,dirname_out

; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
;tab_choix=strarr(1)
;tab_choix(0)='TEMP'

;; Definition des variables
.compile Def_param_bulletin_new
.compile Def_colors
.compile plot_serietemp_test
.compile plot_serietemp_oper
.compile calculer_stats_MYO2
.compile find_indice 
Def_param_bulletin_new

COMMON param_CLASS4_new,variable_name,valeurs_cmax,$
        valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,$
        listemodele,liste_zone_GLOMyo,profondeur3,profondeur4,$
        liste_zone_PSY2_SHOM,tab_prof,tab_prof_model,tab_e3t,tab_prof_2,variable_name_2,$
        variable_name_3,file_mask,file_save

file_save=fichier
file_mask=fichier_mask


; Compilation & Execution 
.compile tracer_suivi_meandiff_supobs
;; choix du type de tracé 
kind='solid_line no_bg grid ' 
clear,titre,units 
;;
;; Create output file
SPAWN,'mkdir -p '+fic_out+'/File_ASCII/'

;; List files
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 

PRINT,filelist,day
print,dir_stats_MERC
CASE modele OF  & $
        'PSY3V2R2': BEGIN & $
         liste_region=strarr(11) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $
        'PSY3V3R1': BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $
        'PSY3V3R2': BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $
         'PSY3QV3R1': BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $
        'PSY2V4R1': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $
        'PSY2V4R2': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $
        'PSY2V4R3': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $
        'PSY2V4R4': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $
        'PSY2QV4R2': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $
	 'PSY4V1R3': BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $
	 'PSY4V2R1': BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $
ENDCASE & $

variable_name_type=variable_name_3
variable_name_type=variable_name
 

calculer_stats_MYO2,modele,file_save,file_mask,$        
 profondeur4,variable_name_type,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,tab_prof,tab_prof_model,tab_e3t

exit,/NO_CONFIRM
