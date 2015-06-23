#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

build_home_env

# See https://github.com/mitchellh/vagrant/issues/5186
#
# Must make sure not using a private key from the base box. The base box
# might get reinstalled with a different private key, and vagrant always
# refers to the exact version, but that might not be bumped:
# -i /Users/nagler/.vagrant.d/boxes/radiasoft-VAGRANTSLASH-fedora/0/virtualbox/vagrant_private_key
#
# Ensure we have the vagrant insecure_private_key in the authorized_keys.
# This may add a duplicate due to the comment string changing, but that's ok.
mkdir -p .ssh
if ! cmp -s "$build_conf/authorized_keys" .ssh/authorized_keys; then
    cat "$build_conf/authorized_keys" >> .ssh/authorized_keys
    chmod -R og-rwx .ssh
fi

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
mv .python-version ~
