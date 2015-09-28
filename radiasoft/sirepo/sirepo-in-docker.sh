#!/bin/bash
set -e
run_dir=$1
port=$2
# Must be in home directory to activate
cd
. ~/.bashrc
# probably isn't needed for non-interactive shells (like this one),
# but ensures pyenv doesn't deactivate on cd "$run_dir"
unset PROMPT_COMMAND
pyenv activate
export PYTHONUNBUFFERED=1
mkdir -p "$run_dir"
cd "$run_dir"
sirepo service uwsgi --run-dir "$run_dir" --port "$port" --docker >& start.log
