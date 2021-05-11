.reset_session
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux

@compile

modele="GLORYS12V1"
modele2="GLORYS12V1-free"
modele3="GLO4"

type='mean'
type='rms'

NB_VALEURS=4
NB_VALEURS2=4
lissage='yes'
;lissage='no'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLORYS12_extend/'

.compile comparaison_GLORYS12
.compile Def_param_bulletin
.compile Def_colors
comparaison_GLORYS12,output_dir,modele,modele2,modele3,lissage,NB_VALEURS,NB_VALEURS2,type
