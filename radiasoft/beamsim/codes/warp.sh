#!/bin/bash
codes_dependencies pygist pyMPI Forthon h5py
codes_download https://depot.radiasoft.org/foss/warp-20150823.tar.gz
cd pywarp90
# INSTALLOPTIONS= turns off INSTALLOPTIONS=--user in Makefile.Forthon
make -f Makefile.Forthon INSTALLOPTIONS= clean install
make -f Makefile.Forthon.pympi \
     FCOMP='-F gfortran --fcompexec /usr/lib64/openmpi/bin/mpifort' \
     clean install
