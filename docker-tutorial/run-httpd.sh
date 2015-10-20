#!/bin/bash
#
# Run the docker httpd container
#
set -e
tag=radiasoft/httpd
name=$(basename "$tag")
port=8000
docker rm -f "$name" >&/dev/null || true
id=$(docker run -d --name="$name" -p "$port:$port" -e HTTPD_PORT="$port" "$tag")
echo "
Container id: $id

Point your browser to: http://localhost:$port

Stop with: docker stop $name
"
