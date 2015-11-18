#!/bin/bash
set -e
db_dir=$1
port=$2
if [[ ! -d $db_dir ]]; then
    echo "$db_dir: db_dir doesn't exist" 1>&2
    exit 1
fi
if [[ ! $port =~ ^[0-9]{2,5}$ ]]; then
    echo "$port: port invalid port (100-99999)" 1>&2
    exit 1
fi
. ~/.bashrc
export PYTHONUNBUFFERED=1
mkdir -p "$db_dir"
cd "$db_dir"
export SIREPO_PKCLI_SERVICE_PORT=$port
export SIREPO_PKCLI_SERVICE_DB_DIR=$PWD
(echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') sirepo service http"; env) > start.log
sirepo service http >> start.log 2>&1
