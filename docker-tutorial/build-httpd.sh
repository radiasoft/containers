#!/bin/bash
#
# Build the docker container to run the busybox httpd
#
set -e
tag=radiasoft/httpd
name=$(basename "$tag")
docker rmi "$tag" >&/dev/null || true
docker build -f Dockerfile-"$name" -t "$tag" .
