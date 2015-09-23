#!/bin/bash
codes_dependencies h5py
codes_download http://genesis.web.psi.ch/Genesis-Beta/genesis-3.2.1-beta.tar.gz
cd Develop/source
make 'LIB=-lgfortran -lstdc++ -lhdf5 -L/usr/lib64 -L/usr/lib64/openmpi/lib' 'CCOMPILER=mpicxx'
set -x
install -m 555 genesis "$codes_bin_dir"
