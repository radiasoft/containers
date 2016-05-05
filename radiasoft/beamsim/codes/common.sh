#!/bin/bash
# Some rpms most codes use
codes_yum install atlas-devel blas-devel lapack-devel openmpi-devel
# Just in case this is installed outside the context for radiasoft/python2,
# we need openmpi in our path (normally set by ~/.bashrc)
if [[ ! ( :$PATH: =~ :/usr/lib64/openmpi/bin: ) ]]; then
    export PATH=/usr/lib64/openmpi/bin:"$PATH"
fi
# Need to be install sequentially. scipy has a build dependency
pip install numpy
pip install matplotlib
pip install scipy
