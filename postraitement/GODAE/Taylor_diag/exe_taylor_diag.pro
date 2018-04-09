;; Creation of Taylor diagram
!path=expand_path('+/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic/')+':'+expand_path('+/home/qualif/LIB/LIB_MIT/DATA')$
+expand_path('/home/cregnier/DEV/Prgs_IDL/FANNING/coyote')+':'+expand_path('+./')$
+':'+expand_path('+/home/cregnier/DEV/Prgs_IDL/FANNING/catalyst')$
+':'+expand_path('+'+!dir)+ ':' + !PATH
; Display the plot in a graphics window.
.compile create_taylor_diag
year='2015'
trim='2'
zone='GLO'
modele='PSY4V2R2'
prof='0-500m'
prof='5-100m'
prof='0-5000m'
prof='0-0m'
var='TEMP'
var='SST'
var='SLA'
dir_in='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V2R2/Stats_GODAE/File_ASCII/MYO/2015_2/'
date1='20150401'
date2='20150630'
; Display the plot in a resizeable graphics window.
cgWindow, 'create_taylor_diag',zone,prof,modele,var,dir_in,date1,date2, WTitle='Taylor Diagram in a Resizeable Graphics Window'
dirname_out='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/'+modele+'/Class4_pics/taylor_diag/'+year+'_'+trim+'/'
name_out='taylor_diagram_'+zone+'_'+prof+'_'+var+'_'+modele+'.ps'
print,dirname_out+name_out
cgPS_Open,dirname_out+name_out
create_taylor_diag,zone,prof,modele,var,dir_in,date1,date2
cgPS_Close
cgPS2Raster,dirname_out+name_out , /PNG, Width=600

