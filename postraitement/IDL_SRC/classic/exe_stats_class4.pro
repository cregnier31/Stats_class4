;------------------------------------------------------------------------
; Fichier batch permettant de generer les stats sur les fichiers class4
; c. regnier Septembre 2007
;-----------------------------------------------------------------------
; extension du path
;!path=expand_path('+/home/cregnier//DEV/Dev_Mare/Interface/Greiner')
!path=expand_path('+/home/cregnier/DEV_oper/MMV_1.0/TOOLS/IDL/Toolbox_11_2007')+':'+expand_path('+/home/cregnier/DEV_oper/MMV_1.0/TOOLS/IDL/DATA')+':'+expand_path('+/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/src/IDL_SRC/Dev_cha_Class4/')+':'+expand_path('+'+!dir)

@compile
@param
@param_class4

;dirin='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/stats/'
;dirin='/home/cregnier/'
fic_out='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/Class4_pics/Time_Series/'
dirname_out=fic_out
filename='/home/cregnier/DEV_oper/MMV_1.0/TOOLS/IDL/DATA/'
;;;;;;
;; Critere de selection
;; 0 : avec critere
;; 1 : sans critere
critere=0
zone='MED'
; Compilation & Execution
dir_mask='/home/cregnier/DEV/Dev_corio/CORIOLIS/Lecture_Class4/stats/MASK/'
dir_stats_MERC='/homelocal2/CLASS4/MERSEA-CLASS4-MERCATOR/STATS/'
dir_stats_FOAM='/homelocal2/CLASS4/MERSEA-CLASS4-FOAM/STATS/'
dir_stats_MFS='/homelocal2/CLASS4/MERSEA-CLASS4-MFS/STATS/'
var1=2
var2=3
month_ini=4
month_fin=9
.compile tracer_stats_mod2
;test_oper_graph,dirgauge

tracer_stats_mod2,month_ini,month_fin,zone,var1,var2,critere
;tracer_stats_mod
exit,/NO_CONFIRM
