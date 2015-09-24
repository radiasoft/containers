#!/bin/bash
codes_dependencies mpi4py
codes_yum install flex cmake eigen3-devel glib2-devel
pip install pyparsing nose

# Can't use these yum packages:
#
# libpng: tries to import libpng.h directly, instead of /usr/include/libpng16/png.h
#
# NLopt: finds it, but then causes a crash in "else" (!nlopt_internal):
#  File "/home/vagrant/tmp/contract-synergia2/packages/nlopt.py", line 26, in <module>
#    nlopt_lib = Option(local_root,"nlopt/lib",default_lib,str,"NLOPT library directory")
#  NameError: name 'default_lib' is not defined
#
# fftw3: doesn't work, b/c packages/fftw3.py looks for libfftw3.so, not libfftw3.so.3
#
# bison: This is bison 3 so incompatible; force to bison_internal
# xsif_yacc.ypp:158:30: error: ‘yylloc’ was not declared in this scope
#        program XSIF_RETURN XSIF_EOL                                                  { drive
#
# tables: always uses synergia's own tables (see below for bug with that)
#
# boost-openmpi-devel: when running synergia:
# ImportError: /lib64/libboost_python.so.1.55.0: undefined symbol: PyUnicodeUCS4_FromEncodedObject

# Can't git clone --depth 1, because:
#     fatal: dumb http transport does not support --depth
git clone -q http://cdcvs.fnal.gov/projects/contract-synergia2

# full clean: git clean -dfx
# partial clean: rm -rf db/*/chef-libs build/chef-libs

cd contract-synergia2
git checkout -b devel origin/devel
./bootstrap

# Once bootstrap is installed, you can do this:
#     rm -rf config; DEBUG_CONFIG=1 ./contract.py --list-targets
#
# This doesn't seem to be right, but it does tell you what is likely to be built
#     grep 1 config/*_internal

# declare as function so can use local vars
synergia_configure() {
    # Turn off parallel make
    local f
    local -a x=()
    local cpus=2
    for f in bison chef-libs fftw3 freeglut libpng nlopt qutexmlrpc qwt synergia2; do
        x+=( "$f"/make_use_custom_parallel=1 "$f"/make_custom_parallel="$cpus")
    done
    for f in bison fftw3 libpng nlopt; do
        x+=( "$f"_internal=1 )
    done
    x+=(
        #NOT in master: boost/parallel="$cpus"
        chef-libs/repo=https://github.com/radiasoft/accelerator-modeling-chef.git
        #chef-libs/branch=5277ecbbdec02e9394eca4e079a651053b6a0ab4
        chef-libs/branch=radiasoft-devel
    )
    ./contract.py --configure "${x[@]}"
}
synergia_configure
unset -f synergia_configure

# 1024MB is not enough for the VM
# http://wiki.vpslink.com/Compile_ANY_program
#export CXXFLAGS='--param ggc-min-expand=0 --param ggc-min-heapsize=8192'

# compacc.fnal.gov has invalid certificate:
# fetching https://compacc.fnal.gov/projects/attachments/download/20/tables-2.1.2.tar.gz
# ....
#  File "/home/vagrant/.pyenv/versions/2.7.10/lib/python2.7/ssl.py", line 808, in do_handshake
#    self._sslobj.do_handshake()
# IOError: [Errno socket error] [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed (_ssl.c:590)
# On apa11, download the file and install in depot/foss
# cd /var/www/virtualhost/depot/foss/
# wget --no-check-certificate https://compacc.fnal.gov/projects/attachments/download/20/tables-2.1.2.tar.gz
# chmod 444 tables-2.1.2.tar.gz
#perl -pi -e 's{https://compacc.fnal.gov/projects/attachments/download/20}{https://depot.radiasoft.org/foss}' packages/pytables_pkg.py

# ./contract.py --dry-run
./contract.py
# git clone --no-checkout -l http://cdcvs.fnal.gov/projects/accelerator-modeling-chef chef-libs

#
# PATH=/home/vagrant/tmp/contract-synergia2/install/bin:$PATH LD_LIBRARY_PATH=/home/vagrant/tmp/contract-synergia2/install/lib:/usr/lib64/openmpi/lib PYTHONPATH=/home/vagrant/tmp/contract-synergia2/install/lib bash -c
# LD_LIBRARY_PATH='install/lib:/usr/lib64/openmpi/lib' PYTHONPATH=install/lib python build/synergia2/examples/fodo_simple1/fodo_simple1.py


# cd build/synergia2
# make test
# 100% tests passed, 0 tests failed out of 177
#
# Total Test time (real) = 421.95 sec
