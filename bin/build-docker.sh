#!/bin/bash
#
# See ./build for usage
#
# Must be absolute; see download/installers/container-run/radiasoft-download.sh
: ${build_docker_cmd:=/bin/bash}
: ${build_docker_entrypoint:=}
: ${build_is_public:=}
: ${build_docker_registry:=}
: ${build_image_add:='docker pull'}
: ${build_dockerfile_aux:=}
: ${build_docker_user:=}

build_docker_version_is_old=
if [[ $(docker --version | perl -n -e '/ (\d+\.\d+)/ && print $1') =~ ^1\.[0-9]$ ]]; then
    build_docker_version_is_old=1
fi

build_clean_container() {
    : nothing to do, because do not have container handle from build
}

build_image() {
    rm -f Dockerfile
    declare cmd=
    if [[ $build_docker_cmd ]]; then
        cmd="CMD $build_docker_cmd"
    fi
    declare entrypoint=
    if [[ $build_docker_entrypoint ]]; then
        entrypoint="ENTRYPOINT $build_docker_entrypoint"
    fi
    declare -a tags=()
    declare bi=$build_image_base
    if [[ $build_docker_registry ]]; then
        declare x=$build_docker_registry/$bi
        if build_image_exists "$x"; then
            bi=$x
        fi
    fi
    tags+=( $(build_image_os_tag "$bi") )
    cat > Dockerfile <<EOF
FROM $bi
MAINTAINER "$build_maintainer"
USER root
ADD . $build_guest_conf
RUN "$build_run"
$cmd
$entrypoint
# run user must be after build_run, because changes user during build
USER ${build_docker_user:-$build_run_user}
$build_dockerfile_aux
EOF
    declare flags=()
    #TODO(robnagler) Really want to check for
    #   IPv4 forwarding is disabled. Networking will not work.
    # However, this doesn't work on older versions, since it prints something
    # similar even when forwarding is disabled.
    if docker build --help 2>&1 | fgrep -q -s -- --network; then
        flags+=( --network=host )
    fi
    declare tag=${build_docker_registry:-docker.io}/$build_image_name:$build_version
    docker build "${flags[@]}" --rm=true --tag="$tag" .
    if [[ ${build_docker_post_hook:-} ]]; then
        # execute the hook, but unset it so it doesn't infinitely recurse
        build_push=${build_push:-} build_docker_post_hook= "$build_docker_post_hook" "$tag" "${flags[@]}" "--user=$build_run_user" --rm=true
    fi
    # We have to tag latest, because docker pulls that on
    # builds if you don't specify a version.
    declare channels=( "$build_version" )
    if [[ ! ${build_docker_version_tag_only:-} ]]; then
        channels+=( latest dev alpha )
    fi
    declare c t r
    declare force=
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
        declare push=''
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
    declare img=$1
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

build_image_os_tag() {
    declare image=$1
    declare ID VERSION_ID
    eval "$( docker run "$image" egrep '^(ID|VERSION_ID)=' /etc/os-release 2>/dev/null || true)"
    declare i=${ID,,}
    declare v=${VERSION_ID}
    case $i in
        centos)
            v=$install_version_centos
            ;;
        fedora)
            v=$install_version_fedora
            ;;
        *)
            : other cases default
            ;;
    esac
    echo "$i-$v"
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
