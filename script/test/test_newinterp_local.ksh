#!/bin/ksh
DIR_EXE="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/bin_local/"
DIR_NML="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/NAMELIST/"
DIR_LOG="/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/log/"
echo ${DIR_NML}interpolate_3D_PROFILE_PSY4V3R1_best_estimate_20150606_test_local.nml
${DIR_EXE}CLASS4_spatial_interpolation_CORIOLIS_local.exe -r 20150606 -c ${DIR_NML}/interpolate_3D_PROFILE_PSY4V3R1_best_estimate_20150606_test_local.nml -m PSY4V3R1 -l ${DIR_LOG}

