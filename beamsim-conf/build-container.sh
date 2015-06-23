#!/bin/bash
#
# Populate a fedora configuration with packages and a configured user (vagrant)
#
set -e
umask 022

set -x

. "$build_env"

# elegant and SDDS
yum install -y "$build_conf"/*.rpm

chmod -R a+rX "$build_conf"

su --login vagrant -c "build_env='$build_env' bash '$build_conf/user-vagrant.sh'"
