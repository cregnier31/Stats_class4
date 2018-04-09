.reset_session
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux

@compile

modele="PSY4V3R1"   
modele2="PSY4V2R2"   
;modele2="MJM105b"   
modele3="T323"   
modele4="GLORYS2V3_free"   
modele5="GLORYS2V1"   

type='mean'
type='rms'

NB_VALEURS=4
NB_VALEURS2=4
lissage='yes'
;lissage='no'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/PSY4V3R1/'

.compile comparaison_PSY4V3_PSY4V2
.compile Def_param_bulletin
.compile Def_colors

comparaison_PSY4V3_PSY4V2,output_dir,modele,modele2,lissage,NB_VALEURS,NB_VALEURS2,type
