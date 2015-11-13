#!/bin/bash
#
# Run synergia as an ipython notebook
#
cd /vagrant
if [[ ! -d beamsim ]]; then
    git clone -q https://github.com/radiasoft/beamsim
fi
exec synergia --ipython notebook
