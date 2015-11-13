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
echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') sirepo service http --db-dir '$db_dir' --port '$port'" > start.log
sirepo service http --db-dir "$db_dir" --port "$port" >>& start.log
