.reset_session

!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')+ $
	          expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/param/')+':' + $
		  expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@compile

day1='20110501'
day2='20110830'

modele2="PSY4V1R3"
lissage='yes'
NB_VALEURS=6
NB_VALEURS2=6
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY3/'+day1+'_'+day2+'/'
.compile comparaison_rmsdiff_PSY3Q_PSY4
.compile Def_param_bulletin_new
.compile Def_colors
.compile plot_serietemp2.pro
comparaison_rmsdiff_PSY3Q_PSY4,output_dir,modele2,lissage ,NB_VALEURS,NB_VALEURS2
