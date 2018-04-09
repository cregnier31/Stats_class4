#!/bin/ksh
ECH="persistence"
ECH="forecast"
export OMP_NUM_THREADS=16
ZONE="ARC"
#./Launch_stats_month.py 2017 7 PSY4V3R1 ${ZONE} ${ECH} 

./Launch_stats_omp_month.py 2017 7 PSY4V3R1 ${ZONE} ${ECH} 
#./Launch_stats_omp_month.py 2017 8 PSY4V3R1 ${ZONE} ${ECH}
#./Launch_stats_omp_month.py 2017 9 PSY4V3R1 ${ZONE} ${ECH}
#./Launch_stats_omp_month.py 2017 10 PSY4V3R1 ${ZONE} ${ECH} 
ZONE="ANT"
#./Launch_stats_month.py 2017 7 PSY4V3R1 ${ZONE} ${ECH} 
#./Launch_stats_omp_month.py 2017 10 PSY4V3R1 ${ZONE} ${ECH}  
#./Launch_stats_omp_month.py 2017 9 PSY4V3R1 ${ZONE} ${ECH}
#./Launch_stats_omp_month.py 2017 8 PSY4V3R1 ${ZONE} ${ECH}
./Launch_stats_omp_month.py 2017 7 PSY4V3R1 ${ZONE} ${ECH}
exit

export OMP_NUM_THREADS=16
/home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/bin/Compute_seaice_stats_ARC_naviti.exe -n /home/cregnier/SVN/mo/TEP/TEP_CLASS4/branches/V4/postraitement/NAMELIST/namelist_aice_ARC_PSY4V3R1_20161026.nml -z ARC

