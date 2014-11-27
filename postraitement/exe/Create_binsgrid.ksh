#!/bin/ksh
#
#  -lgmin :: enter lon min
#  -lgmax :: enter lon max
#  -ltmin :: enter lat min
#  -ltmax :: enter lat max
#  -r : size of cells in degree
res=4
output="/home/qualif/CLASS4/Lecture_Class4_V2.0/static/mask_bins${res}deg.nc"
#../bin/Creation_zone.exe -lgmin -180 -lgmax 180 -ltmin -89 -ltmax 89 -r ${res} -o ${output}
rm  -f ../utils/position_${res}deg.txt
touch  ../utils/position_${res}deg.txt
../bin/Creation_zone.exe -lgmin -180 -lgmax 180 -ltmin -88 -ltmax 88 -r ${res} -o ${output}
#mv fort.40 ../utils/position_${res}deg.txt

