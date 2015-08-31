;extension du path
!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('+../param')+':'+expand_path('+./')$
+':'+expand_path('+../plot')+':'+expand_path('+'+!dir)
; Compilation des parametres globaux
@param
@compile
.compile /home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/GODAE/Timeseries/IDL_SRC/plot_serietemp_oper.pro
.compile /home/qualif/CLASS4/TEP_CLASS4/branches/V3/postraitement/IDL_SRC/param/Def_colors.pro
model='FOAM'
model='PSY4V2R2'
zone='GLO'
date1='20150101'
date2='20150420'
date1='20130501'
;date1='20140101'
date2='20150630'
;date2='20150331'

year=STRMID(date2,0,4)
trim='2'
varname='TEMP'
;varname='SLA'
;varname='SST'
;varname='PSAL'
prof='0-5'
prof='0-5000'
prof='0-0'
prof='5-100'
;prof='300-800'
;prof='800-2000'
;prof='2000-5000'

file='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+model+'/Stats_GODAE/File_ASCII/MYO/all/BasicStats_product_quality_'+model+'_'+zone+'_'+date1+'_'+date2+'_'+varname+'_'+prof+'m.txt'
data=READ_ASCII(file) & field = data.field01
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+model+'/Class4_pics/serie_temp/'+year+'_'+trim+'/'
time=field(0,*)
;date_time=TIMEGEN(N_ELEMENTS(time)-1,UNITS='Days',START= JULDAY(01, 01, 1950))
;time_vec=TIMEGEN(UNITS='Days',STEP_SIZE=1,START= JULDAY(1, 1, 1950)+time(0),FINAL=JULDAY(1, 1, 1950)+time(0))
;time(*)=time(*)+time_vec
;date_time=TIMEGEN(UNITS='Days',STEP_SIZE=1,START= JULDAY(1, 1, 1950)+time(0),  FINAL=JULDAY(1, 1, 1950)+time(N_ELEMENTS(time)-1))
;print,date_time
NB_VALEURS=12
NB_VALEURS2=12
nb_val=        SMOOTH(MEDIAN(transpose(field(1,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)  
nb_val=        SMOOTH(MEDIAN(field(1,*),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)  
mean_diff_hind=SMOOTH(MEDIAN(transpose(field(3,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_hind= SMOOTH(MEDIAN(transpose(field(4,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_F1=  SMOOTH(MEDIAN(transpose(field(5,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_F1=   SMOOTH(MEDIAN(transpose(field(6,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_F3=  SMOOTH(MEDIAN(transpose(field(7,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_F3=   SMOOTH(MEDIAN(transpose(field(8,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_F5=  SMOOTH(MEDIAN(transpose(field(9,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_F5=   SMOOTH(MEDIAN(transpose(field(10,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN) 
mean_diff_P1=  SMOOTH(MEDIAN(transpose(field(11,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_P1=   SMOOTH(MEDIAN(transpose(field(12,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_P3=  SMOOTH(MEDIAN(transpose(field(13,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_P3=   SMOOTH(MEDIAN(transpose(field(14,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_P5=  SMOOTH(MEDIAN(transpose(field(15,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_P5=   SMOOTH(MEDIAN(transpose(field(16,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)


dirname_out=output_dir
name_var=varname+'_'+model+'_Mean_Mean_RMS_'+prof+'m_'+date1+'_'+date2
name_out=output_dir+'/'+name_var
ishold=1
kind='solid_line no_bg grid mean'
output='logo A3 ps'
;output='screen'
titre='Global in situ '+varname+' '+model+' '+prof+'m'
;; 1eme tracé
numx1=time
numx2=mean_diff_hind
ind_color=FSC_COLOR('black')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
legende='Best'
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.3,YNOTE=0.04
ishold=1

;;2eme tracé
numx1=time
numx2=rms_diff_hind
legende=''
ishold=1
ind_color=FSC_COLOR('black')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
; 3eme tracé
numx1=time
numx2=mean_diff_F1
ind_color=FSC_COLOR('blue')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
legende='F1'
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.35,YNOTE=0.04

;4eme tracé
numx1=time
numx2=rms_diff_F1
legende=''
ishold=1
ind_color=FSC_COLOR('blue')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
ishold=0


; 5eme tracé
numx1=time
numx2=mean_diff_F3
ind_color=FSC_COLOR('Steel Blue')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
legende='F3'
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.4,YNOTE=0.04

; 6eme tracé
numx1=time
numx2=rms_diff_F3
legende=''
ishold=1
ind_color=FSC_COLOR('Steel Blue')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
ishold=0

; 7eme tracé
numx1=time
numx2=mean_diff_F5
ind_color=FSC_COLOR('Sky Blue')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
legende='F5'
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.45,YNOTE=0.04

; 8eme tracé
numx1=time
numx2=rms_diff_F5
legende=''
ishold=1
ind_color=FSC_COLOR('Sky Blue')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_P5)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
ishold=0
close_all
do_output,output_dir+'/'+name_out
subst_str,name_out, '-', '_'
SPAWN,'convert -density 600 -background white -flatten -resize 15% '+name_out+'.ps '+name_out+'.gif'
SPAWN,'rm '+name_out+'.ps'



