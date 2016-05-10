#!/bin/bash
build_image_base=postgres:9.5
build_run_user=postgres
build_run_home=/var/lib/postgresql
build_simply=1
build_docker_cmd='[]'
build_dockerfile_aux='ENTRYPOINT []'

# T
# rm -rf /tmp/p; mkdir -p /tmp/p/{data,run}
#docker run -t -u postgres -v /tmp/p/data:/var/lib/postgresql/data -v /tmp/p/run:/run/postgresql -e POSTGRES_PASSWORD=anything -e JPY_PSQL_PASSWORD=anything radiasoft/postgres bash /radia-init.sh
#docker run -t -u postgres -v /tmp/p/data:/var/lib/postgresql/data -v /tmp/p/run:/run/postgresql -e POSTGRES_PASSWORD=anything -e JPY_PSQL_PASSWORD=anything radiasoft/postgres postgres

build_as_root() {
    cd "$build_guest_conf"
    userdel -r "$build_run_user" >& /dev/null || true
    groupadd -g "$build_run_uid" "$build_run_user"
    useradd -m -u "$build_run_uid" -g "$build_run_uid" "$build_run_user"
    rm -rf /docker-entrypoint-initdb.d /docker-entrypoint.sh
    cp radia-init.sh /
    chmod a+r /radia-init.sh
}
