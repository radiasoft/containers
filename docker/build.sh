#!/bin/bash
#
# See ../lib.sh for usage
#

. ../lib.sh

build_bashrc() {
    local user=$(basename "$1")
    local bashrc=$1/.bashrc
    if ! grep -s -q TERM=dumb "$bashrc"; then
        local x=$(cat "$bashrc")
        printf "export TERM=dumb\n$x\n" > "$bashrc"
    fi
}

build_image() {
    rm -f Dockerfile
    cat > Dockerfile <<EOF
FROM $build_image_base
MAINTAINER "$build_maintainer"
ADD . $build_guest_conf
RUN "$build_run"
# Reasonable default for CMD so user doesn't have to specify
CMD /bin/bash
EOF
    local tag=$build_image_name:$build_version
    local latest=$build_image_name:latest
    docker build --rm=true --tag="$tag" .
    docker tag -f "$tag" "$latest"
    # Can't push multiple tags at once:
    # https://github.com/docker/docker/issues/7336
    cat <<EOF
Built: $build_image_name:$build_version
To push to the docker hub:
    docker push '$tag'
    docker push '$latest'
EOF
    cd /
    rm -rf "$build_dir"
}

build_image_clean() {
    if ! build_image_exists "$build_image_name"; then
        return 0
    fi
    local images=$build_image_exists
    local f=
    # Remove none running containers.
    for f in $(docker ps -a \
            | perl -n -e "m{^(\w+)\s.*\s\Q$build_image_name\E[\s:]} && print(qq{\$1\n})"); do
        docker rm "$f"
    done
    for f in $images; do
        docker rmi "$f" 2>/dev/null || true
    done
}

build_image_exists() {
    local img=$1
    build_image_exists=$(docker images -a | perl -ne "m{^${img/:/ +}\\b} && print((split)[2], qq{\\n})")
    [[ -n $build_image_exists ]]
}

build_run() {
    cd "$(dirname "$0")"
    build_init
    if [[ $UID == 0 ]]; then
        build_fedora_patch
        export HOME=/root
        build_user_root
        build_exec_user
        run_as_root
        # Run again, because of update or yum install may reinstall pkgs
        build_fedora_patch
        chown -R "$build_exec_user:$build_exec_user" .
        su "$build_exec_user" "$0"
        build_fedora_clean
    else
        build_bashrc ~
        . ~/.bashrc
        run_as_exec_user
    fi
}

build_user_root() {
    if [[ ! -f /.bashrc ]]; then
        cat > /.bashrc << 'EOF'
export HOME=/root
cd $HOME
. /root/.bash_profile
EOF
    fi
    if [[ ! -f /root/.bash_profile ]]; then
        cp -a /etc/skel/.??* /root
    fi
    build_bashrc /root
}

build_exec_user() {
    if ! id -u $build_exec_user >& /dev/null; then
        groupadd -g 1000 $build_exec_user
        useradd -m -g $build_exec_user -u 1000 $build_exec_user
    fi
}

build_main "$@"
