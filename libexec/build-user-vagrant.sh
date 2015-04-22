#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. /cfg/build-env.sh

build_home_env

# Adds bivio_* commands
. ~/.bashrc

# This line stops a warning from the pyenv installer
bivio_path_insert ~/.pyenv/bin 1
bivio_pyenv_2

# Adds pyenv functions now that pyenv exists
. ~/.bashrc

# local pyenv (fake git needed for bivio_pyenv_local to run)
mkdir -p ~/src/.git
cd ~/src
bivio_pyenv_local
rmdir .git
pyenv activate src

# Install sip and Qt4
build_qt_pkg() {
    local tgz=$1.tar.gz
    shift
    # Put tmp local to user, since for dev, we will just userdel -r vagrant
    # in compile-debug loop.
    local tmp=~/build_qt_pkg
    mkdir "$tmp"
    cd "$tmp"
    curl -s -S -L -O "$build_foss_url/$tgz"
    tar xzf "$tgz"
    rm -f "$tgz"
    cd *
    python configure.py "$@"
    make
    make install
    cd -
    rm -rf "$tmp"
}

build_qt_pkg sip --incdir="$VIRTUAL_ENV/include"
build_qt_pkg PyQt4 --confirm-license -q /usr/lib64/qt4/bin/qmake
