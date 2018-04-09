;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Dernieres Modifs
; C.REGNIER  Juillet   2010 Modifs pour bulletin trimestriel
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux

; Compilation des parametres globaux
@param
@compile
@param_class4
;@config_ORCA025
;@config_PSY3V3R3
;@config_PSY4V2R2
@config_PSY4V3R1
;@config_PSY2V4R4
;@config_GLORYS2V3
dirname_out=fic_out_card
dirin=dir_stats_MERC2
; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
;; Definition des variables
.compile Def_param_bulletin

;; Chargmement des paramètres globaux
Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$
        valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,$
        listemodele,liste_zone_GLOMyo,profondeur3,profondeur4,$
        liste_zone_PSY2_SHOM,tab_prof,tab_prof_model,tab_e3t,tab_prof_2,variable_name_2,$
        variable_name_3,variable_name_4,tab_prof_3,profondeur5,file_mask,file_save

; Choix des  parametres
var1=2
var2=3

;; choix du type de tracé
kind='no_iso stddev UserLevels'
clear,titre,units

;; Compilation & Execution
.compile tracer_stats_gloCLASS4_pcolor_supobs
.compile tracer_mean_gloCLASS4_pcolor_supobs
.compile tracer_rms_gloCLASS4_pcolor_supobs
.compile tracer_skillscore_gloCLASS4_supobs

;;CASE TRIM OF                 & $           
;;  '1' : BEGIN                & $
;;;; JFM
;;          ;print,'trimestre 1' & $
;;          QUAT='JFM'          & $
;;          ;QUAT='Jan'          & $
;;        END                   & $
;;  '2' : BEGIN                  & $
;;;; AMJ                          & $
;;          print,'trimestre 2'& $
;;          QUAT='AMJ'  & $
;;        END       & $
;;  '3' : BEGIN     & $
;;;; JAS            & $
;;          print,'trimestre 3'& $
;;          QUAT='JAS'          & $
;;        END                   & $
;;  '4' : BEGIN                  & $
;;;;  OND                          & $
;;          print,'trimestre 4'& $
;;          QUAT='OND'         & $
;;        END                & $
;;ENDCASE & $
date_title=year
;date_title=QUAT+year
;date_title='ASOND_2006'
print,'date : ',date_title

;; Lancement du programme
;; Boites binsxdeg
;; Bins 2 deg
print ,'-----------------------------------'
print ,'Calcul des stats boites 2deg'
print ,'-----------------------------------'
print,dir_stats_MERC2
print,modele
;; Liste des fichiers à synthétiser
;SPAWN,'ls '+dir_stats_MERC2+ ' | grep rms_diff_R | grep '+modele,filelist 
;SPAWN,'ls '+dir_stats_MERC2+ ' | grep rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
print,'ls '+dir_stats_MERC2+ ' | grep  rms_diff_R'+year+' | grep '+modele

SPAWN,'ls '+dir_stats_MERC2+ ' | grep  rms_diff_R'+year+' | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC2+ ' | grep  rms_diff_R'+year+' | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 

print,filelist
SPAWN,'mkdir -p '+dirname_out
dirname_out=fic_out_card
dirin=dir_stats_MERC2
tracer_stats_gloCLASS4_pcolor_supobs,modele,fichier_mask2,filelist,var1,var2,$
                                zone,kind,dir_stats_MERC2,OPER,date_title, $
				tab_prof
dirname_out=fic_out_card
dirin=dir_stats_MERC2
tracer_stats_gloCLASS4_pcolor_supobs,modele,fichier_mask2,filelist,var1,var2,$
                                zone,kind,dir_stats_MERC2,OPER,date_title, $
				tab_prof_2
exit, /NO_CONFIRM
