#!/bin/bash
codes_dependencies common-rpms
codes_download pyMPI
CC=/usr/lib64/openmpi/bin/mpicc ./configure
make install
