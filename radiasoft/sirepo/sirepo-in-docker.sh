#!/bin/bash
set -e
proto='uwsgi --docker'
if [[ $1 == http ]]; then
    proto=$1
    shift
fi
run_dir=$1
port=$2
if [[ ! -d $run_dir ]]; then
    echo "$run_dir: run_dir doesn't exist" 1>&2
    exit 1
fi
if [[ ! $port =~ ^[0-9]{2,5}$ ]]; then
    echo "$port: port invalid port (100-99999)" 1>&2
    exit 1
fi
. ~/.bashrc
export PYTHONUNBUFFERED=1
mkdir -p "$run_dir"
cd "$run_dir"
sirepo service $proto --run-dir "$run_dir" --port "$port" >& start.log
