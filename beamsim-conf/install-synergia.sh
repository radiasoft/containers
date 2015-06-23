#!/bin/bash
#
# Install synergia
#
cd ..
mkdir fnal
cd fnal
git clone -b devel http://cdcvs.fnal.gov/projects/contract-synergia2 synergia2
cd synergia2
./bootstrap
./contract.py
cd ../..
#!/usr/bin/env python
import os,sys

from contractor import *
from packages import *

local_root.set_tarball_dir("synergia2-devel")
local_root.set_default_target(synergia2)

if 'Package_bundle' in locals():
   synergia2_bundle = Package_bundle(synergia2, ['include/.*'])
   chef_libs_bundle = Package_bundle(chef_libs, ['include/.*'])
   boost_bundle = Package_bundle(boost, ['include/.*', '.*\.a'])
   automake_excludes = ['include/.*', '.*\.a', '.*\.la']
   #fftw3_bundle = Package_bundle(fftw3, automake_excludes)
   #gsl_bundle = Package_bundle(gsl, automake_excludes)
   hdf5_bundle = Package_bundle(hdf5, automake_excludes)
   #matplotlib_bundle = Package_bundle(matplotlib)
   #mpi4py_bundle = Package_bundle(mpi4py)
   #numpy_bundle = Package_bundle(numpy)
   #openmpi_bundle = Package_bundle(openmpi, automake_excludes)
   pygsl_bundle = Package_bundle(pygsl)
   pyparsing_bundle = Package_bundle(pyparsing)
   pytables_bundle = Package_bundle(pytables)

   Bundle('thin', 'synergia2-thin',
          [synergia2_bundle, chef_libs_bundle, fftw3_bundle])

   Bundle('sl6-uspas-02', 'synergia2-sl6-uspas-02',
          [synergia2_bundle, chef_libs_bundle,
           boost_bundle,
           #fftw3_bundle,
           #gsl_bundle,
           hdf5_bundle,
           #matplotlib_bundle,
           #mpi4py_bundle,
           #numpy_bundle,
           #openmpi_bundle,
           pyparsing_bundle,
           pytables_bundle,
           pygsl_bundle,
          ])

   Bundle('osx10_9-uspas-02', 'synergia2-osx10_9-uspas-02',
          [synergia2_bundle, chef_libs_bundle,
           #fftw3_bundle,
           #mpi4py_bundle,
           pyparsing_bundle,
           pytables_bundle,
           pygsl_bundle])

   ##########################################################
   main(sys.argv)
