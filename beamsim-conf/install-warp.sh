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

if [[ $BUILD_WARP_DEBUG ]]; then
    make -f Makefile.Forthon \
        DEBUG='-g --fargs -O0' \
        FARGS=--with_feenableexcept \
        SETUP_PY_DEBUG='-g' \
        clean install
    make -f Makefile.Forthon.pympi \
        DEBUG='-g --fargs -O0' \
        FARGS=--with_feenableexcept \
        FCOMP='-F gfortran --fcompexec /usr/lib64/openmpi/bin/mpifort' \
        MPIPARALLEL= \
        SETUP_PY_DEBUG='-g' \
        clean install
else
    make -f Makefile.Forthon clean install
    make -f Makefile.Forthon.pympi \
        FCOMP='-F gfortran --fcompexec /usr/lib64/openmpi/bin/mpifort' \
        clean install
fi

cd ../..
