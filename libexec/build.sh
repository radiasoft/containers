#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Build a vagrant or docker box.
#
# Called from a build script (container-conf/builder)
#
#    #!/bin/bash
#    build_box=radiasoft/fedora
#    build_base_docker=fedora:21
#    build_base_vagrant=hansode/fedora-21-server-x86_64
#    ../fedora-container/libexec/build.sh
#
# Don't forget to:
#
#    chmod +x container-conf/builder
#    git update-index --chmod=+x container-conf/builder
#
# The build script lives in the conf directory (container-conf) and
# must contain build-fedora.sh, # which will configure the Fedora
# install. All files in the conf directory will be copied into the
# $build_conf directory on guest.
#
# The build directory is $build_type-build.
#
# All commands and variables begin with build.
#
set -e
assert_subshell() {
    # Subshells are strange with set -e so need to return $? after called to
    # test false at outershell.
    return $?
}

build_err() {
    build_msg "$1"
    exit 1
}

build_msg() {
    echo "$1" 1>&2
}

if [[ $PWD =~ container-conf ]]; then
    build_err 'build from the base directory of the repo (where the .git dir is)'
fi

case $1 in
    docker|vagrant)
        build_type=$1
        ;;
    *)
        build_err "Usage: $0 docker|vagrant"
        ;;
esac



build_root=${build_root-$PWD}
build_dir=$build_root/$build_type-build
build_libexec_dir=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)
build_host_conf=$(cd $(dirname "$0"); pwd)
# Cannot contains spaces, because ADD in Dockerfile can't quote the directory
build_conf=/cfg
build_script=$build_conf/build-fedora.sh
build_env_basename=build-env.sh
build_env=$build_conf/$build_env_basename

. $build_libexec_dir/build-env-$build_type.sh

build_msg "Conf: $build_host_conf"
build_msg "Build: $build_dir"

if [[ -d $build_dir && $(type -t build_clean_dir) == function ]]; then
    (
        cd "$build_dir"
        echo "Cleaning: $build_dir"
        build_clean_dir
    ) || exit 1
    rm -rf "$build_dir"
fi

mkdir "$build_dir"
cd "$build_dir"

(
    # TODO(robnagler) consider making local to git server
    echo "export BIVIO_FOSS_MIRROR=${BIVIO_FOSS_MIRROR-https://depot.radiasoft.org/foss}"
    echo "export build_conf='$build_conf'"
    echo "export build_env='$build_env'"
    # Only for debug mode
    port=$(bivio_git_server -port 2>/dev/null || true)
    if [[ $port ]]; then
        # Docker and vagrant always use .1 for host IP
        url="http://$build_container_net.1:$port"
        echo "export BIVIO_GIT_SERVER='$url'"
        echo "*** DEVELOPMENT MODE: Downloads from $url ***" 1>&2
    fi

    cat <<'EOF'
    build_home_env() {
        # Needs to be two lines to catch error on retrieval; bash doesn't complain
        # if an empty file ("false | bash" is true).
        # Root downloads but user and vagrant execute so need to download
        # only once.
        local x=$build_conf/home-env-install.sh
        if [[ ! -r $x ]]; then
            curl -s -S -L "${BIVIO_GIT_SERVER-https://raw.githubusercontent.com}"/biviosoftware/home-env/master/install.sh > "$x"
        fi
        no_perl=1 bash $x
    }
EOF
    echo
) > "$build_env_basename"
assert_subshell

. "./$build_env_basename"

shopt -s nullglob
cp -a "$build_host_conf"/*.* "$build_dir"

build_run
