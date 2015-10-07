#!/bin/bash
set -e
run_dir=$1
port=$2
. ~/.bashrc
export PYTHONUNBUFFERED=1
mkdir -p "$run_dir"
cd "$run_dir"
sirepo service uwsgi --run-dir "$run_dir" --port "$port" --docker >& start.log
