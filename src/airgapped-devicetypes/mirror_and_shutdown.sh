#!/bin/bash

set -e
set -o pipefail

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Starting mc mirror process..."

if [[ -f /usr/src/app/config/env ]]; then
  log "Sourcing environment variables from /usr/src/app/config/env"
  source /usr/src/app/config/env
else
  log "Environment file /usr/src/app/config/env not found"
  exit 1
fi

log "Environment variables loaded. Running mc mirror..."

if mc mirror --overwrite --remove /s3images/ s3/$MINIO_IMAGES_S3_BUCKET; then
  log "mc mirror completed successfully."
  log "Shutting down the container..."
  systemctl poweroff
else
  log "mc mirror failed. Exiting with error."
  exit 1
fi