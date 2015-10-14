#!/bin/bash
#
# make sure vagrant can access docker host user's files in /vagrant
#
docker_setup() {
    local uid=$1
    local gid=$2
    local cmd=$3
    if [[ ! $cmd ]]; then
        echo 'usage: docker-setup <uid> <gid> <command>'
        exit 1
    fi
    if (( $uid != $(id -u) )); then
        usermod -u "$uid" vagrant 2>/dev/null
    fi
    if (( $gid != $(id -g) )); then
        groupmod -g "$gid" vagrant
        chgrp -R "$gid" /home/vagrant
    fi
    exec su - vagrant -c "$cmd"
}

docker_setup "$@"
