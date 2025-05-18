#!/bin/sh
export AWS_DISABLE_MULTIPART_CHECKSUMS=1
export AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED
export AWS_RESPONSE_CHECKSUM_CALCULATION=WHEN_REQUIRED

cd /home/onyxia/work/TEP_CLASS4_creation/tools/
file="headlinescores_class4.py"
aws --endpoint-url https://minio.dive.edito.eu s3 cp "$file" s3://project-oceanbench/class4/  --exclude "*" --include "${file}"
#aws --endpoint-url https://minio.dive.edito.eu s3 cp /home/onyxia/work/CLASS4/TEP_CLASS4_creation/output/ s3://project-oceanbench/class4/ --recursive --exclude "*" --include "class4_*ai*"
