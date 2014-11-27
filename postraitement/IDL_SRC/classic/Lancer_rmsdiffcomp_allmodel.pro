.reset_session

!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@compile
@compile_local

modele2="PSY2V4R1"   
modele3="PSY2V3R1"   
modele4="PSY3V2R2"   
modele2="PSY3V2R2"   

NB_VALEURS=3
NB_VALEURS2=3
;lissage='yes'
lissage='no'
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/all/2010/'
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/all/2010/lissage/'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/all/2010/PSY3_lissage/'
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/all/2010/PSY3/'
;.compile comparaison_rmsdiff2
;.comparaison_rmsdiff_allmodel
.compile comparaison_rmsdiff_pre
comparaison_rmsdiff_pre,output_dir,modele2,lissage,NB_VALEURS,NB_VALEURS2

STOP
;.compile comparaison_rmsdiff_allmodel_PSY2
comparaison_rmsdiff_allmodel,output_dir,modele2,modele3,modele4,lissage,NB_VALEURS,NB_VALEURS2
;;comparaison_rmsdiff_allmodel_PSY2,output_dir,modele2,modele3,modele4,lissage
;.comparaison_meandiff_allmodel
;comparaison_meandiff_allmodel,output_dir,modele2,modele3,modele4,lissage
