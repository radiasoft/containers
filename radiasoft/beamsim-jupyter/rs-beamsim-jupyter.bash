#!/bin/sh
#
# Synergia needs these special paths to work.
#
export SYNERGIA2DIR=$(pyenv prefix)/lib
export LD_LIBRARY_PATH=$SYNERGIA2DIR:/usr/lib64/openmpi/lib
export PYTHONPATH=$SYNERGIA2DIR
