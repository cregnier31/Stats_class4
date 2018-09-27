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
;@config_PSY3V3R3_vturpin
;@config_PSY2V4R4
;@config_GLORYS2V3
;@config_GLORYS2V4
;@config_FOAM
;@config_CGLORS
;@config_ORAS5
;@config_ENSEMBLE
dirname_out=fic_out_card
dirin=dir_stats_MERC2_MLD
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
        variable_name_3,variable_name_4,tab_prof_3,profondeur5,file_mask,file_save,tab_prof_4,tab_prof_5

; Choix des  parametres
var1=2
var2=5

;; choix du type de tracé
kind='no_iso stddev UserLevels'
;kind='temperature difference'
clear,titre,units

;; Compilation & Execution
.compile tracer_stats_MLD_CLASS4_pcolor
.compile tracer_stats_MLD_CLASS4_pcolor_2
.compile plot_pcolor

;; Boites binsxdeg
;; Bins 2 deg
print ,'-----------------------------------'
print ,'Calcul des stats boites 2deg'
print ,'-----------------------------------'
;SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R'+YEAR+month+'  | grep '+modele,filelist 
;SPAWN,'ls '+dir_stats_MERC+ ' | grep -r rms_diff_R'+YEAR+month+' | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
print,dir_stats_MERC2_MLD
;SPAWN,'ls '+dir_stats_MERC2+ ' | grep -r StatsMLD_R'+YEAR+month+' | grep '+modele,filelist 
;SPAWN,'ls '+dir_stats_MERC2+ ' | grep -r StatsMLD_R'+YEAR+month+' | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
SPAWN,'ls '+dir_stats_MERC2_MLD+ ' | grep StatsMLD_R | grep '+modele,filelist
SPAWN,'ls '+dir_stats_MERC2_MLD+ ' | grep StatsMLD_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day
PRINT,filelist
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
  '0' : BEGIN                  & $
;;  OND                          & $
          print,'year'& $
          QUAT='OND'         & $
        END                & $
ENDCASE & $

FILE_MKDIR,fic_out_card 
date_title=year
date_title=QUAT+year
print,'date : ',date_title
tracer_stats_MLD_CLASS4_pcolor,modele,fichier_mask2,filelist,var1,var2,$
                                zone,variable_name,zone,kind,dir_stats_MERC2_MLD,OPER,date_title		
exit, /NO_CONFIRM
