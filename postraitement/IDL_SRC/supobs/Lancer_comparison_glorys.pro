.reset_session
!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux

@compile

modele="GLORYS2V3"   
modele2="MJM105b"   
modele3="T323"   
modele4="GLORYS2V3_free"   
modele5="GLORYS2V1"   

type='mean'
;type='rms'

NB_VALEURS=4
NB_VALEURS2=4
lissage='yes'
;lissage='no'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/GLORYS2V3vsMJM105bvsT323vsG2V3freevsG2V1/'

.compile comparaison_GLORYS2V3vsruns
.compile Def_param_bulletin
.compile Def_colors


comparaison_GLORYS2V3vsruns,output_dir,modele,modele2,modele3,modele4,modele5,lissage,NB_VALEURS,NB_VALEURS2,type
