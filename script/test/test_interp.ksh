#!/bin/ksh
cp /naviti/data5/cregnier/save/* /naviti/data5/cregnier/tmp/ 
/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4//bin/CLASS4_spatial_interpolation_CORIOLIS_test.exe -r 20140301 -c /home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4//NAMELIST/interpolate_3D_PROFILE_GLORYS2V4_best_estimate_20140301.nml -m GLORYS2V4 -l /home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4//log/

