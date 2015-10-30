#!/bin/bash
set -e
run_dir=$1
port=$2
type=${3:-uwsgi --docker}
. ~/.bashrc
export PYTHONUNBUFFERED=1
mkdir -p "$run_dir"
cd "$run_dir"
sirepo service $type --run-dir "$run_dir" --port "$port" >& start.log
