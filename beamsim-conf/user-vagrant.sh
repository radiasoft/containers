#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

mkdir -p ~/src/radiasoft
cd ~/src/radiasoft
pyenv activate src

# TODO(robnagler) SDDS install from RPM directly? Pull from bundle?
install -m 0644 "$build_conf"/sdds* $(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')

# TODO(robnagler) Specify commit version via date
(
    git clone --depth 1 https://github.com/radiasoft/SRW
    cd SRW
    # dependency
    MPICC=/usr/lib64/openmpi/bin/mpicc pip install mpi4py
    make
    make install
)
assert_subshell

(
    gcl shadow3
    cd shadow3
    make
    make libstatic
    python setup.py install
)
assert_subshell

(
    . "$build_conf/install-warp.sh"
)
assert_subshell

(
    gcl radtrack-installer
    gcl radtrack
    cd radtrack
    python setup.py develop
)
assert_subshell
