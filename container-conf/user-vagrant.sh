#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

build_home_env

# Adds bivio_* commands
. ~/.bashrc

# This line stops a warning from the pyenv installer
bivio_path_insert ~/.pyenv/bin 1
bivio_pyenv_2

# Adds pyenv functions now that pyenv exists
. ~/.bashrc

mkdir -p ~/src
cd ~/src
cp "$build_conf/requirements.txt" .
bivio_pyenv_local
pyenv activate src
