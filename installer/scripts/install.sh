#!/bin/bash

echo "== openBalena Installer =="

source /deploy/environment; \
docker-compose -p openbalena -f /deploy/docker-compose.yml "$@"