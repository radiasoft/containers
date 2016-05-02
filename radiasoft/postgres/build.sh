#!/bin/bash
build_image_base=postgres:9.5
build_run_user=postgres
build_run_home=/var/lib/postgresql
build_simply=1
build_docker_cmd='postgres'
build_dockerfile_aux='ENTRYPOINT []'

build_as_root() {
    cd "$build_guest_conf"
    userdel -r postgres >& /dev/null || true
    groupadd -g $build_run_uid $build_run_user
    useradd -M -u $build_run_uid -g $build_run_uid -d /var/lib/postgresql $build_run_user
    cp radia.sh /docker-entrypoint-initdb.d/
    perl -pi -e 's{^\s*exec}{#}' /docker-entrypoint.sh
}
