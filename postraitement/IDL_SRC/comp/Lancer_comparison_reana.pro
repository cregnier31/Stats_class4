.reset_session
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux

@compile

modele="GLORYS2V4"   
modele2="FOAM"   
modele3="CGLORS"   
modele4="ORAS5"   
modele5="ENSEMBLE"   

type='mean'
;type='rms'

NB_VALEURS=4
NB_VALEURS2=4
lissage='yes'
;lissage='no'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLO_RAN/ENV/'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLO_RAN/all/'

.compile comparaison_GLORAN
.compile Def_param_bulletin
.compile Def_colors
comparaison_GLORAN,output_dir,modele,modele2,modele3,modele4,modele5,lissage,NB_VALEURS,NB_VALEURS2,type
