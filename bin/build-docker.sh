#!/bin/bash
#
# See ./build for usage
#
# Must be absolute; see download/installers/container-run/radiasoft-download.sh
: ${build_docker_cmd:=/bin/bash}
: ${build_is_public:=}
: ${build_docker_registry:=}
: ${build_image_add:='docker pull'}
: ${build_dockerfile_aux:=}

build_docker_version_is_old=
if [[ $(docker --version | perl -n -e '/ (\d+\.\d+)/ && print $1') =~ ^1\.[0-9]$ ]]; then
    build_docker_version_is_old=1
fi

build_clean_container() {
    : nothing to do, because do not have container handle from build
}

build_image() {
    rm -f Dockerfile
    local cmd=
    if [[ $build_docker_cmd ]]; then
        cmd="CMD $build_docker_cmd"
    fi
    local bi=$build_image_base
    if [[ $build_docker_registry ]]; then
        local x=$build_docker_registry/$bi
        if build_image_exists "$x"; then
            bi=$x
        fi
    fi
    cat > Dockerfile <<EOF
FROM $bi
MAINTAINER "$build_maintainer"
USER root
ADD . $build_guest_conf
RUN "$build_run"
# Reasonable default for CMD so user doesn't have to specify
$cmd
$build_dockerfile_aux
EOF
    local flags=()
    #TODO(robnagler) Really want to check for
    #   IPv4 forwarding is disabled. Networking will not work.
    # However, this doesn't work on older versions, since it prints something
    # similar even when forwarding is disabled.
    if docker build --help 2>&1 | fgrep -q -s -- --network; then
        flags+=( --network=host )
    fi
    local tag=${build_docker_registry:-docker.io}/$build_image_name:$build_version
    docker build "${flags[@]}" --rm=true --tag="$tag" .
    # We have to tag latest, because docker pulls that on
    # builds if you don't specify a version.
    local channels=( "$build_version" )
    if [[ ! ${build_docker_version_tag_only:-} ]]; then
        channels+=( latest dev alpha )
    fi
    local tags=()
    local c t r
    local force=
    if [[ $build_docker_version_is_old ]]; then
        force=-f
    fi
    # always tag latest
    docker tag $force "$tag" "${tag/$build_version/latest}"
    for r in "${build_is_public:+docker.io}" "$build_docker_registry"; do
        if [[ ! $r ]]; then
            continue
        fi
        for c in "${channels[@]}"; do
            t=$r/$build_image_name:$c
            tags+=( $t )
            if [[ $t != $tag ]]; then
                docker tag $force "$tag" "$t"
            fi
        done
    done
    cat <<EOF
Built: $tag
Channels: ${channels[*]}
EOF
    if [[ ! ${tags[@]+1} ]]; then
        cat <<EOF
To run it:

    docker run --rm -it ${flags[*]} '$tag'
EOF
    elif [[ ${build_push:-} ]]; then
        for t in "${tags[@]}"; do
            echo "Pushing: $t"
            # the tee avoids docker's term escape codes
            docker push "$t" | tee
        done
    else
        local push=''
        for t in "${tags[@]}"; do
            push="$push${push:+; }docker push '$t'"
        done
        cat <<EOF
To run it:

    docker run --rm -it ${flags[*]} '$tag'

After some testing, push the alpha channel:

    $push
EOF
    fi
}

build_image_exists() {
    local img=$1
    if [[ $build_docker_version_is_old ]]; then
        if [[ $build_docker_registry ]]; then
            build_err '$build_docker_registry not allowed in old version of Docker'
        fi
        build_image_exists=$(docker images -a | perl -ne "m{^${img/:/ +}\\b} && print((split)[2], qq{\\n})")
    else
        build_image_exists=$(docker images -q "$img")
    fi
    [[ $build_image_exists ]]
}

build_image_prep() {
    build_image_uri=https://${build_docker_registry:-registry.hub.docker.com}/$build_image_name:$build_version
}

build_init_type() {
    build_is_docker=1
    build_type=docker
}

build_root_setup() {
    export HOME=/root
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
    build_create_run_user
}
