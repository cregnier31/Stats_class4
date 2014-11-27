.reset_session

!path=expand_path('+/home/qualif/LIB/LIB_MIT')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')+':'+expand_path('+'+!dir)

; Compilation des parametres globaux
@compile
@compile_local

year='2011'
trim='1'

modele1="PSY3V3R1"
modele2="PSY2V4R1"   
output_dir='/home/qualif/CLASS4/Lecture_Class4_V2.0/Images/Class4_pics/'
output_dir1=output_dir+modele1+'/suivi_rms/'+year+'_'+trim+'/File_ASCII/'
output_dir2=output_dir+modele2+'/suivi_rms/'+year+'_'+trim+'/File_ASCII/'
output_dir3=output_dir+'Comparaison/previ/'+year+'_'+trim+'/'
.compile plot_serietemp_test3
.compile comparaison_previ
comparaison_previ,output_dir1,output_dir2,output_dir3,modele1,modele2
