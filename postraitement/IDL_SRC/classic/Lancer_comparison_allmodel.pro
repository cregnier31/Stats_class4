.reset_session

!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/param')+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags')$
+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/plot')+':'+expand_path('+'+!dir)


; Compilation des parametres globaux
@compile
@compile_local

modele2="PSY3V3R2"   
modele3="PSY2V4R2"   
modele4="PSY2V4R3"   

;type='mean'
type='rms'

NB_VALEURS=60
NB_VALEURS2=60
lissage='yes'
;lissage='no'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/new_rtr2/no_legend/'
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/new_rtr2/'


.compile comparaison_allmodel

comparaison_allmodel,output_dir,modele2,modele3,modele4,lissage,NB_VALEURS,NB_VALEURS2,type
