;extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux
@param
@compile
.compile /home/cregnier/DEV_naviti/TEP_CLASS4_GODAE/postraitement/IDL_SRC/plot_serietemp_oper.pro
.compile /home/qualif/CLASS4/TEP_CLASS4/trunk/postraitement/IDL_SRC/param/Def_colors.pro
;file='/data/rd_exchange/cregnier/Stats_GODAE/File_ASCII/PSY3V3R3/BasicStats_product_quality_PSY3V3R3_GLO_20130101_20131231_SLA_0-0m.txt'
model1='FOAM'
model2='PSY4V2R2'
model3='PSY3V3R3'

zone='GLO'
date1='20150101'
date2='20150420'
;date1='20130501'
;date2='20150331'
varname='TEMP'
varname='SLA'
;varname='SST'
;varname='PSAL'
prof='0-5'
prof='0-5000'
prof='0-0'
;prof='5-100'
;prof='300-800'
;prof='800-2000'
;prof='2000-5000'

file1='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+model1+'/Stats_GODAE/File_ASCII/MYO/no_qc/BasicStats_product_quality_'+model1+'_'+zone+'_'+date1+'_'+date2+'_'+varname+'_'+prof+'m.txt'
file2='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+model2+'/Stats_GODAE/File_ASCII/MYO/no_qc/BasicStats_product_quality_'+model2+'_'+zone+'_'+date1+'_'+date2+'_'+varname+'_'+prof+'m.txt'
file3='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+model3+'/Stats_GODAE/File_ASCII/MYO/no_qc/BasicStats_product_quality_'+model3+'_'+zone+'_'+date1+'_'+date2+'_'+varname+'_'+prof+'m.txt'
data1=READ_ASCII(file1) & field = data1.field01
clear,field
data2=READ_ASCII(file2) & field = data2.field01
clear,field
data3=READ_ASCII(file3) & field = data3.field01
clear,field
output_dir='/home/cregnier/DEV_naviti/TEP_CLASS4_GODAE/postraitement/IDL_SRC/intercomp/'

time=field(0,*)
NB_VALEURS=12
NB_VALEURS2=12
nb_val=        SMOOTH(MEDIAN(field(1,*),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)  
mean_diff_hind=SMOOTH(MEDIAN(transpose(field(3,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_hind= SMOOTH(MEDIAN(transpose(field(4,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_F1=  SMOOTH(MEDIAN(transpose(field(5,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_F1=   SMOOTH(MEDIAN(transpose(field(6,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_hind2=  SMOOTH(MEDIAN(transpose(field2(3,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_hind2=   SMOOTH(MEDIAN(transpose(field2(4,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_F1_2=  SMOOTH(MEDIAN(transpose(field2(5,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_F1_2=   SMOOTH(MEDIAN(transpose(field2(6,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
mean_diff_hind3=  SMOOTH(MEDIAN(transpose(field3(3,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_hind3=   SMOOTH(MEDIAN(transpose(field3(4,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_F1_3=  SMOOTH(MEDIAN(transpose(field3(5,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_F1_3=   SMOOTH(MEDIAN(transpose(field3(6,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)


dirname_out=output_dir
name_var=varname+'_intercomp_'+model1+'_'+model2+'_'+model3+'_Mean_Mean_RMS_'+prof+'m_'+date1+'_'+date2
name_out=output_dir+'/'+name_var
ishold=1
kind='solid_line no_bg grid mean'
output='A3 ps'
;output='screen'
titre='Global in situ '+varname+' '+model1+' '+model2+' '+model3+' '+prof+'m'
;; FOAM
;; 1eme tracé
numx1=time
numx2=mean_diff_hind
ind_color=FSC_COLOR('black')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
legende='Best '+model1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.3,YNOTE=0.04
ishold=1

;;2eme tracé
numx1=time
numx2=rms_diff_hind
legende=''
ishold=1
ind_color=FSC_COLOR('black')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_F1)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
; 3eme tracé
numx1=time
numx2=mean_diff_F1
ind_color=FSC_COLOR('gray')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
legende='F1_'+model1
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.35,YNOTE=0.04

;4eme tracé
numx1=time
numx2=rms_diff_F1
legende=''
ishold=1
ind_color=FSC_COLOR('gray')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
ishold=0

;; PSY4
mod2=STRMID(model2,0,4)
; 5eme tracé
numx1=time
numx2=mean_diff_hind2
ind_color=FSC_COLOR('Steel Blue')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
legende='Best '+mod2
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.4,YNOTE=0.04

; 6eme tracé
numx1=time
numx2=rms_diff_hind2
legende=''
ishold=1
ind_color=FSC_COLOR('Steel Blue')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
ishold=0

; 7eme tracé
numx1=time
numx2=mean_diff_F1_2
ind_color=FSC_COLOR('Sky Blue')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
legende='F1_'+mod2
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.45,YNOTE=0.04

; 8eme tracé
numx1=time
numx2=rms_diff_F1_2
legende=''
ishold=1
ind_color=FSC_COLOR('Sky Blue')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val

mod3=STRMID(model3,0,4)    
; 9eme tracé
numx1=time
numx2=mean_diff_hind3
ind_color=FSC_COLOR('Red')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
legende='Best_'+mod3
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.5,YNOTE=0.04

; 10eme tracé
numx1=time
numx2=rms_diff_hind3
legende=''
ishold=1
ind_color=FSC_COLOR('Red')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val

; 11eme tracé
numx1=time
numx2=mean_diff_F1_3
ind_color=FSC_COLOR('Orange Red')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
legende='F1_'+mod3
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.55,YNOTE=0.04

; 12eme tracé
numx1=time
numx2=rms_diff_F1_3
legende=''
ishold=1
ind_color=FSC_COLOR('Orange Red')
cmin=MIN(mean_diff_F1)
cmax=MAX(rms_diff_F1)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
ishold=0
close_all
do_output,output_dir+'/'+name_out
subst_str,name_out, '-', '_'
SPAWN,'convert -density 600 -background white -flatten -resize 15% '+name_out+'.ps '+name_out+'.gif'
SPAWN,'rm '+name_out+'.ps'



