#!/bin/bash
#
# See ./build for usage
#

build_image_add='docker pull'

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
    local alpha=$build_image_name:alpha
    local latest=$build_image_name:latest
    docker build --rm=true --tag="$tag" .
    # We have to tab latest, because docker pulls that on
    # builds if you don't specify a version. Since build_image_base
    # is without a version, we'll have to keep latest.
    docker tag -f "$tag" "$latest"
    # Can't push multiple tags at once:
    # https://github.com/docker/docker/issues/7336
    cat <<EOF
Built: $build_image_name:$build_version

To run it, you can then:

    docker run -i -t $tag su - $build_exec_user

After some testing, tag it for the alpha channel:

    docker tag '$tag' '$alpha'
    docker push '$tag'
    docker push '$latest'
    docker push '$alpha'
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
    # Remove any exited containers. Will fail if there is a running container
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
    if [[ ! -x /su-vagrant ]]; then
        cat > /su-vagrant << 'EOF'
#!/bin/bash
uid=$1
gid=$2
cmd=$3
if [[ ! $cmd ]]; then
    echo "usage: $(basename "$0") <uid> <gid> <command>" 1>&2
    exit 1
fi
if (( $uid != $(id -u vagrant) )); then
    usermod -u "$uid" vagrant
fi
if (( $gid != $(id -g vagrant) )); then
    groupmod -g "$gid" vagrant
    chgrp -R "$gid" ~vagrant
fi
exec su - vagrant -c "$cmd"
EOF
        chmod 555 /su-vagrant
    fi
    if [[ ! -f /root/.bash_profile ]]; then
        cp -a /etc/skel/.??* /root
    fi
    if ! id -u $build_exec_user >& /dev/null; then
        groupadd -g 1000 $build_exec_user
        useradd -m -g $build_exec_user -u 1000 $build_exec_user
    fi
    local x=/etc/sudoers.d/$build_exec_user
    if [[ ! -f $x ]]; then
        build_yum install sudo
        echo "$build_exec_user ALL=(ALL) NOPASSWD: ALL" > "$x"
        chmod 440 "$x"
    fi
}
