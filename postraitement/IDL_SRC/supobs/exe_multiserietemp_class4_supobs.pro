;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; author: C.REGNIER  Decembre  2013 :: Adaptation aux nouveaux fichiers stats
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+/home/cregnier/DEV/Prgs_IDL/FANNING/coyote')$
+':'+expand_path('+'+!dir)+ ':' + !PATH


; Compilation des parametres globaux
@param
@compile
;@config_ORCA025
@param_class4
@config_PSY3V3R3
;@config_PSY2V4R4
@config_PSY4V2R2
; Definition des paths
dirname_out=fic_out_serie_temp
dirin=dir_stats_MERC
; Definition des variables  
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
;; Definition des variables
.compile Def_param_bulletin

;; Chargmement des paramètres globaux
Def_param_bulletin
.compile Def_colors

COMMON param_CLASS4,variable_name,valeurs_cmax,$
        valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,$
        listemodele,liste_zone_GLOMyo,profondeur3,profondeur4,$
        liste_zone_PSY2_SHOM,tab_prof,tab_prof_model,tab_e3t,tab_prof_2,variable_name_2,$
        variable_name_3,variable_name_4,tab_prof_3,profondeur5,file_mask,file_save

; Compilation & Execution 
print,"Tracer serie temp" 
.compile tracer_multiserietemp_CLASS4_supobs
;; choix du type de tracé 
kind='grid solid_line no_bg grid ' 
clear,titre,units 
;;
SPAWN,'ls '+dir_stats_MERC+ ' | grep rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC+ ' | grep rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
SPAWN,'mkdir -p '+dirname_out+'File_ASCII/'
PRINT,filelist,day
CASE modele OF  & $

        'PSY3V3R3': BEGIN & $
         print ,'Modele :: ',modele & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

        'PSY4V2R2': BEGIN & $
         liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

        'PSY2V4R4': BEGIN & $
         liste_region=strarr(6) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $

ENDCASE & $


CASE TRIM OF                 & $
  '1' : BEGIN                & $
;; JFM
          QUAT='JFM'          & $
        END                   & $
  '2' : BEGIN                  & $
;; AMJ                          & $
          QUAT='AMJ'  & $
        END       & $
  '3' : BEGIN     & $
;; JAS            & $
          QUAT='JAS'          & $
        END                   & $
  '4' : BEGIN                  & $
;;  OND                          & $
          QUAT='OND'         & $
        END                & $
ENDCASE & $
date_title=QUAT+year

print,date_title

 ; tracer_multiserietemp_CLASS4_supobs,modele,fichier_mask,$        
 ;    tab_prof,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER 
;; Display mode 
;; 0 : no_screen 
;; 1 :: screen
display=0
transparency=0
  tracer_multiserietemp_CLASS4_supobs,display,date_title,modele,fichier_mask,$        
     tab_prof_3,kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,transparency 

exit, /NO_CONFIRM
