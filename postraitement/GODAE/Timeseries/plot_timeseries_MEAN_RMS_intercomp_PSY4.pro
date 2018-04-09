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
model1='PSY4V2R2'
model2='PSY4V3R1'

zone='GLO'
date1='20150101'
date2='20151231'
varname='SST'
prof='0-0'

file1='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+model1+'/Stats_GODAE/File_ASCII/MYO/2015/BasicStats_product_quality_'+model1+'_'+zone+'_'+date1+'_'+date2+'_'+varname+'_'+prof+'m.txt'
file2='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+model2+'/Stats_GODAE/File_ASCII/MYO/2015/BasicStats_product_quality_'+model2+'_'+zone+'_'+date1+'_'+date2+'_'+varname+'_'+prof+'m.txt'
print,file1
print,file2

data1=READ_ASCII(file1) & field = data1.field01
clear,field
print,'Read1 OK'
data2=READ_ASCII(file2) & field = data2.field02
clear,field
print,'Read2 OK'
output_dir='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/Comparaison_systemes/PSY4V3R1/'+varname+'/'

time=field(0,*)
NB_VALEURS=12
NB_VALEURS2=12
nb_val=        SMOOTH(MEDIAN(field(1,*),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)  
mean_diff_hind=SMOOTH(MEDIAN(transpose(field(3,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_hind= SMOOTH(MEDIAN(transpose(field(4,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
mean_diff_hind2=  SMOOTH(MEDIAN(transpose(field2(3,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)
rms_diff_hind2=   SMOOTH(MEDIAN(transpose(field2(4,*)),NB_VALEURS), NB_VALEURS2, /EDGE_TRUNCATE, /NAN)

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
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_hind)
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
numx2=mean_diff_hind2
ind_color=FSC_COLOR('Steel Blue')
cmin=MIN(mean_diff_hind)
cmax=MAX(rms_diff_hind)
legende='Best '+mod2
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2=legende,OUTPUT_FILE=name_out,RIGHT=nb_val,XNOTE=0.4,YNOTE=0.04

; 4eme tracé
numx1=time
numx2=rms_diff_hind2
legende=''
ishold=1
ind_color=FSC_COLOR('Steel Blue')
cmin=MIN(mean_diff_best)
cmax=MAX(rms_diff_best)
ishold=1
plot_serietemp_oper,1.5,ind_color,PLOT_KIND=kind,NOTE2='',OUTPUT_FILE=name_out,RIGHT=nb_val
ishold=0
close_all
do_output,output_dir+'/'+name_out
subst_str,name_out, '-', '_'
SPAWN,'convert -density 600 -background white -flatten -resize 15% '+name_out+'.ps '+name_out+'.gif'
SPAWN,'rm '+name_out+'.ps'



