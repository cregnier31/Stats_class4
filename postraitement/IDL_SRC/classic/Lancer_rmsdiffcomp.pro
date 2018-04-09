.reset_session

!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@compile
@compile_local

year='2010'
trim='3'

modele2="PSY3V2R2"
;modele2="PSY2V3R1"   
;lissage='yes'
lissage='no'
NB_VALEURS=3
NB_VALEURS2=3
;lissage='no'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/Comparaison_PSY2/'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/Comparaison_PSY3/'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY2/'+year+'_'+trim+'/'
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY3/'+year+'_'+trim+'/'
;.compile comparaison_rmsdiff2
.compile comparaison_rmsdiffMYO

comparaison_rmsdiffMYO,output_dir,modele2,lissage ,NB_VALEURS,NB_VALEURS2
