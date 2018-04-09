#!/bin/ksh
EXE='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4//bin_local/CLASS4_spatial_interpolation_CORIOLIS_RAW.exe'
NAMELIST='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4//NAMELIST/interpolate_3D_PROFILE_GLORYS2V4_best_estimate_19940429.nml'
LOG='/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4//log/'
${EXE} -r 19940429 -c ${NAMELIST} -m  GLORYS2V4 -l ${LOG}

exit


python TEP_CLASS4.py --config=PSY4V3R1 --date1=20140101 --date2=20141231 --src=CORIO --data=profile --typemod=allege
exit
exe="../bin/CLASS4_spatial_interpolation_CORIOLIS.exe"
dateval="20140105"
namelist="../NAMELIST/interpolate_3D_PROFILE_PSY4V3R1_best_estimate_${dateval}.nml"
config='PSY4V3R1'
${exe} -r ${dateval} -c ${namelist} -m ${config}
#codexe = '%s -r %s -c %s -m %s' %(exe,dateval,nml,cl_config_use)

