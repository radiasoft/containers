#!/bin/bash
force=
if [[ $1 = -f ]]; then
    force=$1
fi
x=$(docker ps -a -q)
if [[ $x ]]; then
    echo Containers: $x
    docker rm $force $x
fi
x=$(docker images --filter dangling=true -q)
if [[ $x ]]; then
    echo Images: $x
    docker rmi $force $x
fi
