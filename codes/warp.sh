#!/bin/bash
codes_dependencies pygist pyMPI Forthon
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
