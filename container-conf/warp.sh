#!/bin/bash
#
# Install warp
#
set -e
. ~/.bashrc
pyenv activate src
radiasoft=~/src/radiasoft
mkdir -p "$radiasoft"
cd "$radiasoft"
gcl pygist
cd pygist
python setup.py config
python setup.py install

cd "$radiasoft"
gcl pyMPI
cd pyMPI
CC=/usr/lib64/openmpi/bin/mpicc ./configure
# --with-debug
make install

cd "$radiasoft"
gcl Forthon
cd Forthon
python setup.py install

# -g --parallel
# -f /usr/lib64/openmpi/bin/mpifort

cd "$radiasoft"
gcl warp
cd warp/pywarp90
make -f Makefile.Forthon \
    DEBUG='-g --fargs -O0' \
    SETUP_PY_DEBUG='-g' \
    clean install
make -f Makefile.Forthon.pympi \
    MPIPARALLEL= \
    FCOMP='-F gfortran --fcompexec /usr/lib64/openmpi/bin/mpifort' \
    DEBUG='-g --fargs -O0' \
    SETUP_PY_DEBUG='-g' \
    clean install
