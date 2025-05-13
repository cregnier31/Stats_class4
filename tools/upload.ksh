#!/bin/sh
export AWS_DISABLE_MULTIPART_CHECKSUMS=1
export AWS_REQUEST_CHECKSUM_CALCULATION=WHEN_REQUIRED
export AWS_RESPONSE_CHECKSUM_CALCULATION=WHEN_REQUIRED

cd /home/onyxia/work/CLASS4/TEP_CLASS4_creation/output/
#for file in class4_*ai*; do
#  if [ -f "$file" ]; then
#    aws --endpoint-url https://minio.dive.edito.eu s3api put-object \
#      --bucket project-oceanbench \
#      --key class4/"$file" \
#      --body "$file" \
#      --no-verify-ssl
#  fi
#done
for file in class4_20241*ai*; do
  if [ -f "$file" ]; then
    echo $file
    aws --endpoint-url https://minio.dive.edito.eu s3 cp "$file" s3://project-oceanbench/class4/  --exclude "*" --include "class4_*ai*"
  fi
done
#aws --endpoint-url https://minio.dive.edito.eu s3 cp /home/onyxia/work/CLASS4/TEP_CLASS4_creation/output/ s3://project-oceanbench/class4/ --recursive --exclude "*" --include "class4_*ai*"
