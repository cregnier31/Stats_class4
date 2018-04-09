.reset_session
!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)



; Compilation des parametres globaux
@compile
@compile_local

type='mean'
type='rms'

NB_VALEURS=8
NB_VALEURS2=8
NB_VALEURS=2
NB_VALEURS2=2
lissage='yes'
;lissage='no'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/PSY4V3R1/'
.compile Def_param_bulletin
.compile comparaison_model_PSY4
.compile Def_colors
.compile plot_serietemp_test4 
.compile plot_serietemp_test5 
.compile plot_serietemp_oper3
comparaison_model_PSY4,output_dir,lissage,NB_VALEURS,NB_VALEURS2,type
