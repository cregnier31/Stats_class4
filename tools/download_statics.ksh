#!/bin/sh
variable="profile"
variable="currents"
file="headlinescores_class4.py"
file="score3D_class4_20240103_20241231_oceanbench.csv"
file="scores_oceanbench_class4_2D.png"


aws --endpoint-url https://minio.dive.edito.eu s3 cp s3://project-oceanbench/class4/ ../data/observations/ --exclude "*" --recursive --include $file
#aws --endpoint-url https://minio.dive.edito.eu s3 cp s3://project-oceanbench/class4/ ../data/observations/ --exclude "*" --recursive --include "*GLO12V4_PGS_mdt_high_nbpts1.nc"
#aws --endpoint-url https://minio.dive.edito.eu s3 cp s3://project-oceanbench/class4/ ../data/observations/ --exclude "*" --recursive --include "013_048_filtr_2024.tar"
#aws --endpoint-url https://minio.dive.edito.eu s3 cp s3://project-oceanbench/class4/ ../data/observations/ --exclude "*" --recursive --include "class4_2024**${variable}*"
