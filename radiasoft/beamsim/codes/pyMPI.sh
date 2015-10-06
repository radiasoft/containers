#!/bin/bash

#TODO(robnagler) not completely working with pyenv.
#
# setup() is not pulling up augmentedMakefile. See
#
#     mpirun -np 1 pyMPI unittest/extension.py
#
# distutils.sysconfig.get_makefile_filename is being monkey patched correctly,
# but I suspect that makefile is not being pulled in by setup to do the build.
# There's another get_makefile_filename in sysconfig, which may be used by
# distutils.
# Also PyMPITest is not working. Dies with a core dump. Didn't debug that
# yet. The other test scripts seem to work.
#
# To run the tests in a pyenv virtualenv, you have to install pyMPI. If
# you run ./pyMPI, it will fail:
#
#   [py2;@v pyMPI]$ ./pyMPI unittest/popen.py
#   ImportError: numpy.core.multiarray4444 failed to import
#   ImportError: ('Internal failure', <type 'exceptions.ImportError'>, 'numpy.core.multiarray5555 failed to import')
#
# This one was tough to figure out, but the wrong "site" is being imported
# so sys.path is using the pyenv 2.7.10, not the virtualenv (py2).
#
# The ultimate problem is that pyenv links the python binary in a virtualenv
# so it gets the wrong path compiled in the binary. Since pyMPI is a python
# interpreter (not an extension) it needs to bootstrap with a bunch of overrides
# that have to happen in the right order.

codes_dependencies common
codes_download pyMPI
CC=/usr/lib64/openmpi/bin/mpicc ./configure
perl -pi -e s/2.7.10/py2/g pyMPI_Config.h Makefile config.status config.log
perl -pi -e 's{(?=\>+\s*augmentedMakefile)}{\| perl -p -e s/2.7.10/py2/g }' \
     Makefile
make install
