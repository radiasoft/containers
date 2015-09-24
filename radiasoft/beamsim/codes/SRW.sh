#!/bin/bash
#Too slow. git repo has too much junk
#codes_download SRW
codes_dependencies mpi4py
codes_download https://depot.radiasoft.org/foss/SRW-20150923.tar.gz
make
make install
