#!/bin/bash
#
# See ./build for usage
#
# Must be absolute; see download/installers/container-run/radiasoft-download.sh
: ${build_docker_cmd:=/bin/bash}
: ${build_docker_entrypoint:=}
: ${build_docker_post_hook:=}
: ${build_docker_registry:=${RADIA_RUN_OCI_REGISTRY:-}}
: ${build_docker_user:=}
: ${build_dockerfile_aux:=}
: ${build_image_add:="$RADIA_RUN_OCI_CMD pull"}
: ${build_is_public:=}
: ${build_push:=}
# Must be defined by $build_script
# build_image_base

build_clean_container() {
    : nothing to do, because do not have container handle from build
}

build_image() {
    declare os_channel=$(_build_image_docker_file)
    #TODO(robnagler) Really want to check for
    #   IPv4 forwarding is disabled. Networking will not work.
    declare flags=( --network=host )
    declare tag=${build_docker_registry:+$build_docker_registry/}$build_image_name:$build_version
    $RADIA_RUN_OCI_CMD build "${flags[@]}" --progress=plain --rm=true --tag="$tag" .
    if [[ $build_docker_post_hook ]]; then
        # execute the hook, but unset it so it doesn't infinitely recurse
        build_push=$build_push build_docker_post_hook= "$build_docker_post_hook" "$tag" "${flags[@]}" "--user=$build_run_user" --rm=true
    fi
    declare channels=( "$build_version" )
    if [[ ! ${build_docker_version_tag_only:-} ]]; then
        channels+=( alpha dev latest $os_channel )
    fi
    declare c t
    declare push=
    declare r=${tag%%:*}
    for c in "${channels[@]}"; do
        t=$r:$c
        push+="$RADIA_RUN_OCI_CMD push '$t'|tee;"$'\n'
        if [[ $t != $tag ]]; then
            $RADIA_RUN_OCI_CMD tag "$tag" "$t"
        fi
    done
    cat <<EOF
Built: $tag
Channels: ${channels[*]}
EOF
    declare m=$(cat <<EOF
To run it:

$RADIA_RUN_OCI_CMD run --rm -it ${flags[*]} '$tag'
EOF
)
    if ! [[ $build_docker_registry || $build_is_public ]]; then
        echo "$m"
        return
    fi
    if [[ $build_push ]]; then
        (set +x; eval "$push")
    else
        cat <<EOF
$m

After some testing, push:

$push
EOF
    fi
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

_build_image_docker_file() {
    rm -f Dockerfile
    declare cmd=
    if [[ $build_docker_cmd ]]; then
        cmd="CMD $build_docker_cmd"
    fi
    declare entrypoint=
    if [[ $build_docker_entrypoint ]]; then
        entrypoint="ENTRYPOINT $build_docker_entrypoint"
    fi
    declare bi=$build_image_base
    if [[ $build_docker_registry ]]; then
        declare x=$build_docker_registry/$bi
        if [[ $($RADIA_RUN_OCI_CMD images -q "$x") ]]; then
            bi=$x
        fi
    fi
    # POSIT: if $build_docker_registry then all channels exist (including os channel)
    declare v=$(_build_image_os_tag "$bi")
    if [[ ! $bi =~ : ]]; then
        bi+=:$v
    fi
    cat > Dockerfile <<EOF
FROM $bi
MAINTAINER "$build_maintainer"
USER root
COPY . $build_guest_conf
RUN "$build_run"
$cmd
$entrypoint
# run user must be after build_run, because changes user during build
USER ${build_docker_user:-$build_run_user}
$build_dockerfile_aux
EOF
    echo "$v"
}

_build_image_os_tag() {
    declare image=$1
    declare ID VERSION_ID
    eval "$( $RADIA_RUN_OCI_CMD run --rm "$image" egrep '^(ID|VERSION_ID)=' /etc/os-release 2>/dev/null || true)"
    declare i=${ID,,}
    declare v=$VERSION_ID
    if [[ ! $image =~ : ]]; then
        case $i in
            centos)
                v=$install_version_centos
                ;;
            fedora)
                v=$install_version_fedora
                ;;
            *)
                : other cases default to $VERSION_ID
                ;;
        esac
    fi
    echo "$i-$v"
}
