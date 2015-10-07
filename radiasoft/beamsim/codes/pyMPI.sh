#!/bin/bash
#TODO(robnagler) not completely working with pyenv???
codes_dependencies common
codes_download pyMPI
CC=/usr/lib64/openmpi/bin/mpicc ./configure
make install
