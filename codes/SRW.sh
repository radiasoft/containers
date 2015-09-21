#!/bin/bash
codes_download SRW
MPICC=/usr/lib64/openmpi/bin/mpicc pip install mpi4py
make
make install
