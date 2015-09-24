#!/bin/bash
codes_dependencies common-rpms
codes_yum install fftw2-devel
codes_dependencies mpi4py
#Too slow. git repo has too much junk:
#   codes_download SRW
codes_download https://depot.radiasoft.org/foss/SRW-20150923.tar.gz
make
make install
