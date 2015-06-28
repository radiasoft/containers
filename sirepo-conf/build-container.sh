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

#TODO(robnagler) remove once rebuild fedora21
if ! id vagrant &>/dev/null; then
    if ! getent group vagrant &>/dev/null; then
        groupadd -g 1000 vagrant
    fi
    useradd --create-home -g vagrant -u 1000 vagrant
fi

chmod -R a+rX "$build_conf"

su --login vagrant -c "build_env='$build_env' bash '$build_conf/user-vagrant.sh'"
