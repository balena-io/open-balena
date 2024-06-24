#!/bin/bash

set -e

echo "Starting mc mirror..."
mc mirror --overwrite --remove /s3images/ s3/$MINIO_IMAGES_S3_BUCKET
echo "mc mirror completed successfully."

# Only power off if mc mirror succeeds
systemctl poweroff
