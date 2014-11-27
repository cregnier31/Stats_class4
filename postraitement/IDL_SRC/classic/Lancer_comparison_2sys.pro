.reset_session

!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/param')+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags')$
+':'+expand_path('+/home/qualif/CLASS4/IDL_RMS_Mean_diags/plot')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@compile
@compile_local

;year='2010'
;trim='3'

modele="PSY3V3R1"
modele2="PSY3V3R2"
;modele="PSY2V4R2"
;modele2="PSY2V4R3"
type='mean'
;type='rms'

lissage='yes'
;lissage='no'
NB_VALEURS=60
NB_VALEURS2=60
;lissage='no'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/Comparaison_PSY2/'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/Comparaison_PSY3/'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY2/'+year+'_'+trim+'/'
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY3/'+year+'_'+trim+'/'
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY3V3R1vsR2/2007-2011/'
;output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/Comparaison/PSY2V4R2vsR3/2007-2011/'

fic_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics_RTR/'
path='/2007-2011/'

.comparaison_2systems

comparaison_2systems,output_dir,modele,modele2,lissage ,NB_VALEURS,NB_VALEURS2,type,fic_dir,path
