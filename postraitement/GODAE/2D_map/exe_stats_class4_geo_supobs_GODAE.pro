;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; C.REGNIER  October   2013 Plot 2D bins maps for GODAE intercomparison
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/param')+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags')$
+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux
@param
@compile
@param_class4
@config_PSY4QV2R2
;@config_PSY3QV3R3
;@config_BLK
;@config_GIOPS
;@config_FOAM
;@config_HYCOM
dirin=dir_stats_MERC
print,dirin
; Definition des variables 
tab_choix=strarr(2)
tab_choix(0)='SAL'
tab_choix(1)='TEMP'
;; Definition des variables
.compile Def_param_bulletin

;; Chargemement des paramètres globaux
Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$
        valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,$
        liste_TEST,listemodele,liste_zone_GLOMyo,profondeur3,$
        profondeur4,liste_zone_PSY2_SHOM,tab_prof,tab_model,$
        tab_e3t,tab_prof_2,variable_name_2,variable_name_3,$
        variable_name_4,tab_prof_3,profondeur5,file_mask,file_save


; Choix des  parametres
var1=1
var2=2
variable='TEMP'
variable='PSAL'
variable='SLA'
variable='SST'



;; choix du type de tracé
kind='no_iso stddev UserLevels'
;kind='temperature difference'
clear,titre,units

;; Compilation & Execution
.compile tracer_stats_gloCLASS4_pcolor_supobs_GODAE
.compile tracer_mean_gloCLASS4_pcolor_supobs_GODAE
.compile tracer_rms_gloCLASS4_pcolor_supobs_GODAE
.compile tracer_stats_gloCLASS4_pcolor_supobs_GODAE_2D
;;; Boites binsxdeg
print ,'-----------------------------------'
print ,'Calcul des stats boites 2deg pour la varible ::',variable
print ,'-----------------------------------'

CASE variable OF                             & $
 	 'TEMP': BEGIN                       & $
	   type_var='profile_votemper'       & $
           fichier=fichier_TEMP              & $
	 END                                 & $ 
	 'PSAL':BEGIN                        & $
           type_var='profile_vosaline'       & $
           fichier=fichier_PSAL              & $
	 END                                 & $
	 'SLA':BEGIN                         & $
           type_var='sossheig'               & $
           fichier=fichier_SLA               & $
	 END      	                     & $ 
	 'SST':BEGIN                         & $ 
           type_var='SST'                    & $ 
           fichier=fichier_SST               & $ 
	 END     	                     & $ 
ENDCASE
;month='11'
;SPAWN,'ls '+dir_stats_MERC2+ ' | grep '+type_var+' | grep  rms_diff_bins2deg_R2015'+month,filelist 
SPAWN,'ls '+dir_stats_MERC2+ ' | grep '+type_var+' | grep  rms_diff_bins2deg_R2015',filelist 
print,filelist
variable_name=strarr(9)
variable_name(0)=variable
variable_name(1)='HDCST_'+variable
variable_name(2)='FRCST1D_'+variable
variable_name(3)='FRCST3D_'+variable
variable_name(4)='FRCST5D_'+variable
variable_name(5)='PERS1D_'+variable
variable_name(6)='PERS3D_'+variable
variable_name(7)='PERS5D_'+variable
variable_name(8)='CLIM_'+variable
variable_name_type=variable_name
print,variable_name_type
datetrim=year
date_title=datetrim

CASE variable OF              & $
  'TEMP' : BEGIN                & $
          print,variable        & $
          dirname_out=fic_out_card+"T_S/"+datetrim+"/" & $
          tracer_stats_gloCLASS4_pcolor_supobs_GODAE,modele,fichier,fichier_mask2,filelist,var1,var2, $   
                                                     profondeur2,variable_name_type,zone,kind,dir_stats_MERC2,OPER,date_title, $
                               			     tab_prof_2,tab_model,tab_e3t                                          & $
;;          tracer_mean_gloCLASS4_pcolor_supobs_GODAE,modele,fichier,fichier_mask2,filelist,var1,var2, $   
;;                                                     profondeur2,variable_name_type,zone,kind,dir_stats_MERC2,OPER,date_title, $
;;                               			     tab_prof_2,tab_model,tab_e3t  & $                                         & $
;;          tracer_rms_gloCLASS4_pcolor_supobs_GODAE,modele,fichier,fichier_mask2,filelist,var1,var2, $   
 ;;                                                    profondeur2,variable_name_type,zone,kind,dir_stats_MERC2,OPER,date_title, $
  ;;                             			     tab_prof_2,tab_model,tab_e3t                                          & $
        END                   & $
  'PSAL' : BEGIN                  & $
          print,'PSAL'         & $
          dirname_out=fic_out_card+"T_S/"+datetrim+"/" & $
          tracer_stats_gloCLASS4_pcolor_supobs_GODAE,modele,fichier,fichier_mask2,filelist,var1,var2, $   
                                                     profondeur2,variable_name_type,zone,kind,dir_stats_MERC2,OPER,date_title, $
                               			     tab_prof_2,tab_model,tab_e3t                                          & $
        ;;  tracer_mean_gloCLASS4_pcolor_supobs_GODAE,modele,fichier,fichier_mask2,filelist,var1,var2, $   
        ;;                                             profondeur2,variable_name_type,zone,kind,dir_stats_MERC2,OPER,date_title, $
        ;;                       			     tab_prof_2,tab_model,tab_e3t   & $
        ;;  dirname_out=fic_out_card+"T_S/"+datetrim+"/" & $
        ;;  tracer_rms_gloCLASS4_pcolor_supobs_GODAE,modele,fichier,fichier_mask2,filelist,var1,var2, $   
        ;;                                             profondeur2,variable_name_type,zone,kind,dir_stats_MERC2,OPER,date_title, $
        ;;                      			     tab_prof_2,tab_model,tab_e3t  & $
        END       & $
  'SLA' : BEGIN     & $
         print,variable         & $
          dirname_out=fic_out_card+"SLA/"+datetrim+"/" & $
	 tracer_stats_gloCLASS4_pcolor_supobs_GODAE_2D,modele,fichier,fichier_mask2,filelist, $
                                                       var1,var2,variable_name,               $
                                                       zone,kind,dir_stats_MERC2,date_title   & $
        END                   & $
  'SST' : BEGIN                  & $
         print,variable         & $
          dirname_out=fic_out_card+"SST/"+datetrim+"/" & $
	 tracer_stats_gloCLASS4_pcolor_supobs_GODAE_2D,modele,fichier,fichier_mask2,filelist, $
                                                       var1,var2,variable_name,               $
                                                       zone,kind,dir_stats_MERC2,date_title   & $
        END                & $
ENDCASE & $
STOP
exit, /NO_CONFIRM
;; Bins 4 deg
;; Calcul des skill scores
print ,'-----------------------------------'
print ,'Calcul des skill scores'
print ,'-----------------------------------'
;kind='no_iso stddev UserLevels'
;SPAWN,'ls '+dir_stats_MERC3+ ' | grep -r rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC3+ ' | grep rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC3+ ' | grep rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 
kind='no_iso sla UserLevels publi'
print,variable_name_type
var1=2
var2=7
dirname_out=fic_out_card
;fic_out_skill
variable_name_type=variable_name_3
tracer_skillscore_gloCLASS4_supobs,modele,fichier,fichier_mask3,filelist,var1,var2,$
                                  profondeur2,variable_name_type,zone,kind,dir_stats_MERC3,OPER,date_title, $
                                  tab_prof_2,tab_prof_model,tab_e3t

tracer_skillscore_gloCLASS4_supobs,modele,fichier,fichier_mask3,filelist,var1,var2,$
                                  profondeur4,variable_name_type,zone,kind,dir_stats_MERC3,OPER,date_title, $
