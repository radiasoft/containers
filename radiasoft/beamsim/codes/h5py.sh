#!/bin/bash
codes_dependencies common
codes_yum install hdf5-devel hdf5-openmpi
# Need to install Cython first, or h5py build fails
pip install --upgrade Cython
pip install --upgrade h5py
