#!/bin/bash
codes_download pyMPI
CC=/usr/lib64/openmpi/bin/mpicc ./configure
make install
