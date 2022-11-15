.reset_session
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux

@compile

modele="GLO12V4-light"
modele2="PSY4V3R1-light"

type='mean'
type='rms'

NB_VALEURS=4
NB_VALEURS2=4
lissage='yes'
;lissage='no'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLO12V4/'
.compile comparaison_GLO12V4
.compile Def_param_bulletin
.compile Def_colors
comparaison_GLO12V4,output_dir,modele,modele2,lissage,NB_VALEURS,NB_VALEURS2,type
