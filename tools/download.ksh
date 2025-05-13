#!/bin/sh
aws --endpoint-url https://minio.dive.edito.eu s3 cp s3://project-oceanbench/class4/ ./ --exclude "*" --include "class4_202501*SST*"

