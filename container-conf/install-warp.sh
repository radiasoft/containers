#!/bin/bash
#
# Install warp
#

# TODO(robnagler) Installer environment guaranteed: what are
#   the assertions(?)

gcl pygist
cd pygist
python setup.py config
python setup.py install
cd ..

gcl pyMPI
cd pyMPI
CC=/usr/lib64/openmpi/bin/mpicc ./configure
# --with-debug
make install
cd ..

gcl Forthon
cd Forthon
python setup.py install
cd ..

gcl warp
cd warp/pywarp90
FARGS = --with_feenableexcept
warpg
make -f Makefile.Forthon \
    DEBUG='-g --fargs "--with_feenableexcept -O0"' \
    SETUP_PY_DEBUG='-g' \
    clean install
make -f Makefile.Forthon.pympi \
    MPIPARALLEL= \
    FCOMP='-F gfortran --fcompexec /usr/lib64/openmpi/bin/mpifort' \
    DEBUG='-g --fargs "--with_feenableexcept -O0"' \
    SETUP_PY_DEBUG='-g' \
    clean install
cd ../..
