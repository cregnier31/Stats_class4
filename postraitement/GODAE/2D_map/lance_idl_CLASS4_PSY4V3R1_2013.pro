cd, '/home/qualif/LIB/LIB_MIT/merge_libnicoVSliberic/'
@compile
cd, '/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/GODAE/2D_map'
.compile compute_stats_class4_geo_supobs_GODAE_YEAR
.compile tracer_stats_gloCLASS4_pcolor_supobs_GODAE
.compile tracer_stats_gloCLASS4_pcolor_supobs_GODAE_2D
.compile Def_param_bulletin
@param_class4
@param
compute_stats_class4_geo_supobs_GODAE_YEAR,DIR_OUT='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/Class4_pics/Cartes/GODAE/',DIR_INPUT='/sortref/calval/DATA_COLOCATIONS/T_S_data_new/PSY4V3R1/Stats_GODAE/RMS_DIFF/bins2deg/',MODEL='PSY4V3R1',YEAR='2013',QUART='',zone='T'
exit
