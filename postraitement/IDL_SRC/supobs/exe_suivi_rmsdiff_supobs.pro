;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
; c.REGNIER  Fevrier   2007 grosse modifs
; c.REGNIER  Mai       2009 Bulletin trimestriel
; c.REGNIER  Fevrier   2010 Generalisation du code
; C.REGNIER  Septembre 2011 Ajout de supobs
; C.REGNIER  Janvier   2013  Maj
;-----------------------------------------------------------------------
; extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux
@param
@param_class4
@compile

;@config_PSY2V4R4
;@config_PSY3V3R3
;@config_PSY2V4R4
;@config_PSY4V2R2
;@config_IBI36V2R1
;@config_GLORYS2V3
@config_PSY4V3R1
@config_GLORYS12V1
;@config_GLORYS2V3_free
;@config_GLORYS2V1
;@config_MJM105b
;@config_T323
;@config_PSY3V3R3
;@config_PSY4V2R2
;@config_PSY2V4R4

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

Def_param_bulletin

COMMON param_CLASS4,variable_name,valeurs_cmax,$
        valeurs_cmax_sal,valeurs_cmax2,valeurs_cmax2_sal, $
        profondeur,profondeur2,liste_zone,liste_zone_PSY2,liste_TEST,$
        listemodele,liste_zone_GLOMyo,profondeur3,profondeur4,$
        liste_zone_PSY2_SHOM,tab_prof,tab_prof_model,tab_e3t,tab_prof_2,variable_name_2,$
        variable_name_3,variable_name_4,tab_prof_3,profondeur5,file_mask,file_save

file_mask=fichier_mask


;; Filtrage ou non de la série temporelle
lissage='yes'
lissage='no'
; Nombre de points de filtrage
NB_VALEURS=2
NB_VALEURS2=2

; Compilation & Execution 
.compile tracer_suivi_rmsdiff_supobs
.compile tracer_suivi_meandiff_supobs
;; choix du type de tracé 
kind='solid_line no_bg grid ' 
clear,titre,units 
;;
;; Create output file
SPAWN,'mkdir -p '+fic_out+'/File_ASCII/'

;; List files
SPAWN,'ls '+dir_stats_MERC+ ' | grep  rms_diff_R | grep '+modele,filelist 
SPAWN,'ls '+dir_stats_MERC+ ' | grep  rms_diff_R | grep '+modele+ ' | cut -f4 -d_ | cut -f2 -dR | cut -f1 -d.',day 

PRINT,filelist,day
print,dir_stats_MERC
print,liste_zone
print,modele
CASE modele OF  & $

        'PSY3V3R3': BEGIN & $
         liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

	 'T321':BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

	 'IBI36V2R1': BEGIN & $
         liste_region=strarr(3) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $

        'PSY2V4R4': BEGIN & $
         liste_region=strarr(7) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $

        'PSY2QV4R4': BEGIN & $
         liste_region=strarr(7) & $
         liste_region=liste_zone_PSY2 & $
         ENDCASE & $

         'PSY4V3R1': BEGIN & $
         liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
         ;liste_region=strarr(1) & $
         ;liste_region(*)='BALTIC' & $
         ENDCASE & $

	 'GLORYS12V1':BEGIN & $
         liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
          ENDCASE & $

	 'MJM105b':BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ;liste_region=strarr(1) & $
         ;liste_region(0)='GLO' & $
         ENDCASE & $

	 'T323':BEGIN & $
         liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ;liste_region=strarr(1) & $
         ;liste_region(0)='GLO' & $
         ENDCASE & $
       
	 'GLORYS2V3' :BEGIN & $
	 liste_region=strarr(14) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

	 'MJM105b' :BEGIN & $
	 liste_region=strarr(13) & $
         liste_region(*)=liste_zone(*) & $
         ENDCASE & $

ENDCASE & $
;;; Lancé du tracé de la rms diff et la mean diff sur les couches MYOcean 
;; 0-5, 5-100,100-300,300-800,800-2000
tracer_suivi_rmsdiff_supobs,modele,file_mask,$
kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,tab_prof,lissage,NB_VALEURS,NB_VALEURS2
dirname_out=fic_out
dirin=dir_stats_MERC
tracer_suivi_meandiff_supobs,modele,file_mask,$
kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,tab_prof,lissage,NB_VALEURS,NB_VALEURS2
;exit,/NO_CONFIRM
;;STOP

;;;; Lancé du tracé de la rms diff et la mean diff sur les couches classiques
;;;; 0-50, 50-100, 100-150 ...
dirname_out=fic_out
dirin=dir_stats_MERC
tracer_suivi_rmsdiff_supobs,modele,file_mask,$
kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,tab_prof_2,lissage,NB_VALEURS,NB_VALEURS2
;
dirname_out=fic_out
dirin=dir_stats_MERC
tracer_suivi_meandiff_supobs,modele,file_mask,$
kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,tab_prof_2,lissage,NB_VALEURS,NB_VALEURS2

;;;;;;;;;; Reanalyse
;;;; 0-100, 100-300, 300-800, 800-2000,0-2000
dirname_out=fic_out
dirin=dir_stats_MERC
tracer_suivi_rmsdiff_supobs,modele,file_mask,$
kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,tab_prof_3,lissage,NB_VALEURS,NB_VALEURS2
dirname_out=fic_out
dirin=dir_stats_MERC
;;
tracer_suivi_meandiff_supobs,modele,file_mask,$
kind,filelist,dir_stats_MERC,day,valeurs_cmax2,valeurs_cmax2_sal,liste_region,tab_choix,OPER,tab_prof_3,lissage,NB_VALEURS,NB_VALEURS2
exit,/NO_CONFIRM




