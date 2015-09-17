#!/bin/bash
build_tag_base=radiasoft/python2

run_as_root() {
    :
}

run_as_vagrant() {
    mkdir -p ~/src/radiasoft
    (
        cd ~/src/radiasoft
        git clone --depth 1 https://github.com/radiasoft/SRW
        cd SRW
        # dependency
        MPICC=/usr/lib64/openmpi/bin/mpicc pip install mpi4py
        make
        make install
    )
    return $?
}
