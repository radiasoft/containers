#!/bin/bash
#
# Build a docker container
#
build_main() {
    build_tag=$1
    if ! [[ $build_tag =~ ^[-_[:alnum:]]+/[-_[:alnum:]]+$ ]]; then
        build_err "$build_tag: invalid or missing docker tag\nusage: $0 <docker/tag>\n  -- <docker/tag> must be a directory"
    fi
    build_script=$build_tag/build.sh
    if [[ ! -f $build_script ]]; then
        build_err "$build_script: missing config file in current directory."
    fi
    build_host_conf=$(cd "$build_tag"; pwd)

    . "./$build_script"

    local v=
    for v in build_tag build_tag_base; do
        if [[ ! -v $v ]]; then
            build_err "\$$v: variable must defined in $build_script"
        fi
    done

    for v in run_as_root run_as_vagrant; do
        if ! declare -f "$v" >& /dev/null; then
            build_err "$v(): function must be defined in $build_script"
        fi
    done

    if ! build_image_exists "$build_tag_base"; then
        build_err "$build_tag_base: not in docker images -a"
    fi

    build_init

    build_dir=/var/tmp/radiasoft-container-$UID-$RANDOM
    build_version=$(date -u +%Y%m%d.%H%M%S)
    build_guest_conf=/conf
    build_guest_script=/conf/$(basename "$build_script")

    build_msg "Conf: $build_host_conf"
    build_msg "Build: $build_dir"

    build_image_clean

    rm -rf "$build_dir"
    mkdir "$build_dir"
    cd "$build_dir"
    cp -a "$build_host_conf"/* .
    {
        echo '#!/bin/bash'
        for f in $(compgen -A function | grep ^build_); do
            declare -f "$f"
        done
        cat <<EOF
build_version='$build_version'
build_tag='$build_tag'
build_tag_base='$build_tag_base'
build_maintainer='RadiaSoft LLC <docker@radiasoft.net>'
. "$build_guest_script"
build_run
EOF
    } > build-run.sh
    chmod +x build-run.sh

    build_run="$build_guest_conf/build-run.sh"
    build_image
}

build_image() {
    rm -f Dockerfile
    cat > Dockerfile <<EOF
FROM $build_tag_base
MAINTAINER "$build_maintainer"
ADD . $build_guest_conf
RUN "$build_run"
# Reasonable default for CMD so user doesn't have to specify
CMD /bin/bash
EOF
    local tag=$build_tag:$build_version
    local latest=$build_tag:latest
    docker build --rm=true --tag="$tag" .
    docker tag -f "$tag" "$latest"
    # Can't push multiple tags at once:
    # https://github.com/docker/docker/issues/7336
    cat <<EOF
Built: $build_tag:$build_version
To push to the docker hub:
    docker push '$tag'
    docker push '$latest'
EOF
    cd /
    rm -rf "$build_dir"
}

build_image_clean() {
    if ! build_image_exists "$build_tag"; then
        return
    fi
    # Remove none running containers.
    for f in $(docker ps -a \
            | perl -n -e "m{^(\w+)\s.*\s\Q$build_tag\E[\s:]} && print(qq{\$1\n})"); do
        docker rm "$f"
    done
    docker rmi "$build_tag"
}

build_image_exists() {
    local img=$1
    docker images -a | grep -s -q "^${img/:/ *} "
}

build_init() {
    set -e
    if [[ $build_debug ]]; then
        set -x
    fi
}

build_err() {
    build_msg "$1"
    exit 1
}

build_msg() {
    printf "$1\n" 1>&2
}

#
# Tools for inside container build
#

build_run() {
    cd "$(dirname "$0")"
    build_init
    if [[ $UID == 0 ]]; then
        export HOME=/root
        build_user_root
        build_user_vagrant
        run_as_root
        chown -R vagrant:vagrant .
        su vagrant "$0"
    else
        run_as_vagrant
    fi
}

build_bashrc() {
    local user=$(basename "$1")
    local bashrc=$1/.bashrc
    if ! grep -s -q TERM=dumb "$bashrc"; then
        local x=$(cat "$bashrc")
        printf "export TERM=dumb\n$x\n" > "$bashrc"
        chown "$user:$user" "$bashrc"
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

build_user_vagrant() {
    if ! id -u vagrant >& /dev/null; then
        groupadd -g 1000 vagrant
        useradd -m -g vagrant -u 1000 vagrant
        build_bashrc ~vagrant
    fi
}

build_main "$@"
