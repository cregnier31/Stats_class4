;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
;-----------------------------------------------------------------------
; extension du path
;!path=expand_path('+/home/cregnier//DEV/Dev_Mare/Interface/Greiner')
; extension du path
!path=expand_path('+/home/cregnier/DEV_oper/Mare_1.0/TOOLS/IDL/Toolbox_11_2007')+':'+expand_path('+/home/cregnier/DEV_oper/Mare_1.0/TOOLS/IDL/DATA')+':'+expand_path('+/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/src/IDL_SRC/Dev_cha_Class4')+':'+expand_path('+'+!dir)

@compile
@param
@param_class4
;@param_class4
;; Definition des path

;; Choix du modele
;modele='PSY3V2'

;modele='WOA05'
;modele='Levitus2005'
 modele='PSY3V2'
; modele='FOAM'
;  modele='PSY3V1'
; modele='MFS'
;modele='Levitus2005'
;modele='TOPAZ'

;dirin='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/stats/MFS/'
dirin='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/stats/new_'+modele+'/'
;dirin='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/stats/TOPAZ/'
;dirin='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/stats/FOAM/'
dir_mask='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/stats/MASK/'
fic_out='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/Tracer/Figures2/SerieTemp_Rmsdiff/'
filename='/home/cregnier/DEV_oper/Mare_1.0/TOOLS/IDL/DATA/'
dirname_out=fic_out

;; Choix des fichiers
fichier=modele+'_T_2007_stats.nc'
;fichier='TOPAZ_T_2007_stats.nc'
;fichier='FOAM_T_2007_stats.nc'
;fichier='FOAM_T_2007_stats.nc'
;fichier='MFS_T_2007_stats.nc'

fichier_mask='maskbox.nc'

;; Definition des variables
variable=strarr(22)
variable(0)='TEMP'
variable(1)='PSAL'
variable(2)='HDCST_TEMP'
variable(3)='HDCST_PSAL'
variable(4)='ANA_TEMP'
variable(5)='ANA_PSAL'
variable(6)='FRCST3D_TEMP'
variable(7)='FRCST3D_PSAL'
variable(8)='FRCST6D_TEMP'
variable(9)='FRCST6D_PSAL'
variable(10)='PERS3D_TEMP'
variable(11)='PERS3D_PSAL'
variable(12)='PERS6D_TEMP'
variable(13)='PERS6D_PSAL'
variable(14)='FSTGS_TEMP'
variable(15)='FSTGS_PSAL'
variable(16)='TMLEV'
variable(17)='SMLEV'
variable(18)='TMMED'
variable(19)='SMMED'
variable(20)='TMBAL'
variable(21)='SMBAL'

profondeur=strarr(6)
profondeur(0)='0-5m'
profondeur(1)='5-100m'
profondeur(2)='100-500'
profondeur(3)='500-2000m'
profondeur(4)='2000-5000m'
profondeur(5)='0-6000m'

; Choix des  parametres
;choix de la profondeur
;; ici toutes

;; choix du domaine
dom='zoom MNATL4 1/4 mercator'
zone='Atlantic'
;dom='zoom MNATL4 1/8'

;; dom='zoom Indian 1/4 mercator'
;;zone='Indian'

;dom='zoom  Pacific 1/4 mercator'
;; Pacific
;dom='zoom Medit 1/16'
;dom='zoom Medit 1/4 mercator'
;; dom='zoom Indian 1/4 mercator'
;dom='zoom  Pacific 1/4 mercator'

;; choix du type de tracé
kind='no_iso'
clear,titre,units
; Compilation & Execution
.compile tracer_serietemp_CLASS4.pro
tracer_serietemp_CLASS4,modele,fichier,fichier_mask,profondeur,variable,dom,kind,zone

exit, /NO_CONFIRM
