;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Dernieres Modifs
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
;@config_PSY2V4R1_RTR
;@config_PSY2V3R1
;@config_PSY3V2R2
;@config_PSY3V3R1_test2
;@config_PSY3V3R1_test3
;@config_PSY2V4R1_EN3
;@config_PSY2V4R1
;@config_PSY3V3R1_JAPAN
@config_PSY3V3R1
;@config_PSY3V3R1_EN3
;@config_PSY4V1R3_EN3
;@config_PSY4V1R3
;@config_PSY3V3R2
;@config_PSY2V4R1
;@config_PSY2V4R2_EN3
;@config_PSY2V4R2
;@config_PSY2V4R3

dirname_out=fic_out_card
dirin=dir_stats_MERC
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
       profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,listemodele,liste_zone_GLOMyo,profondeur3

; Choix des  parametres
var1=2
var2=23
;var2=21

;; choix du type de tracé
kind='no_iso stddev UserLevels'
;kind='temperature difference'
clear,titre,units

;; Compilation & Execution
.compile tracer_stats_gloCLASS4_trimes
.compile tracer_stats_gloCLASS4_pcolor
.compile tracer_skillscore_gloCLASS4

;; Liste des fichiers à synthétiser
;SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele,filelist 
;SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
;PRINT,filelist
;; Lancement du programme
;; Boite Stats zones ASSIM
print ,'-----------------------------------'
print ,'Calcul des stats boites assim'
;print ,'-----------------------------------'
;tracer_stats_gloCLASS4_trimes,modele,fichier,fichier_mask,filelist,var1,var2,$
;                                  profondeur2,variable_name,zone,kind,dir_stats_MERC,OPER
;

;; Boites binsxdeg
;; Bins 2 deg
print ,'-----------------------------------'
print ,'Calcul des stats boites 2deg'
print ,'-----------------------------------'
SPAWN,'ls '+dir_stats_MERC2+ ' | grep -r rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC2+ ' | grep -r rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
PRINT,filelist
;date_title=year
;date_title='2010'
CASE TRIM OF                 & $           
  '1' : BEGIN                & $
;; JFM
          print,'trimestre 1' & $
          QUAT='JFM'          & $
        END                   & $
  '2' : BEGIN                  & $
;; AMJ                          & $
          print,'trimestre 2'& $
          QUAT='AMJ'  & $
        END       & $
  '3' : BEGIN     & $
;; JAS            & $
          print,'trimestre 3'& $
          QUAT='JAS'          & $
        END                   & $
  '4' : BEGIN                  & $
;;  OND                          & $
          print,'trimestre 4'& $
          QUAT='OND'         & $
        END                & $
ENDCASE & $

date_title=QUAT+year
print,'date : ',date_title
; tracer_stats_gloCLASS4_pcolor,modele,fichier,fichier_mask2,filelist,var1,var2,$
;                                profondeur2,variable_name,zone,kind,dir_stats_MERC2,OPER,date_title
;

;; Bins 4 deg
;; Calcul des skill scores
print ,'-----------------------------------'
print ,'Calcul des skill scores'
print ,'-----------------------------------'
;kind='no_iso stddev UserLevels'
SPAWN,'ls '+dir_stats_MERC3+ ' | grep -r rms_diff_R | grep '+modele,filelist 

kind='no_iso sla UserLevels publi'
kind='unknown difference no_iso UserLevels publi'
print,variable_name
tracer_skillscore_gloCLASS4,modele,fichier,fichier_mask3,filelist,var1,var2,$
                                  profondeur2,variable_name,zone,kind,dir_stats_MERC3,OPER

exit, /NO_CONFIRM


;;dirname_out=fic_out_card+'Bins2deg_'

;  tracer_stats_gloCLASS4_trimes,modele,fichier,fichier_mask2,filelist,var1,var2,$
;                                  profondeur2,variable_name,zone,kind,dir_stats_MERC2,OPER


;dirname_out=fic_out_skill

exit, /NO_CONFIRM
