#!/bin/bash
# Some rpms most codes use
codes_yum install atlas-devel blas-devel lapack-devel openmpi-devel
# Just in case this is installed outside the context for radiasoft/python2
pip install numpy
pip install matplotlib
