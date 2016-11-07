#!/bin/bash
#
# See ./build for usage
#
: ${build_docker_cmd:=/bin/bash}
: ${build_image_add:='docker pull'}
: ${build_dockerfile_aux:=}

_docker_client_version=$(docker --version | perl -n -e '/ (\d+\.\d+)/ && print $1')

build_clean_container() {
    : nothing to do, because do not have container handle from build
}

build_image() {
    rm -f Dockerfile
    local cmd=
    if [[ $build_docker_cmd ]]; then
        cmd="CMD $build_docker_cmd"
    fi
    cat > Dockerfile <<EOF
FROM $build_image_base
MAINTAINER "$build_maintainer"
ADD . $build_guest_conf
RUN "$build_run"
# Reasonable default for CMD so user doesn't have to specify
$cmd
$build_dockerfile_aux
EOF
    local tag=$build_image_name:$build_version
    docker build --rm=true --tag="$tag" .
    # We have to tag latest, because docker pulls that on
    # builds if you don't specify a version.
    local channels=( latest dev alpha )
    local tags=( $tag )
    local push="docker push '$tag'"
    local c t
    local force=
    if [[ $_docker_client_version =~ ^1\.[0-9]$ ]]; then
        force=-f
    fi
    for c in "${channels[@]}"; do
        t=$build_image_name:$c
        tags+=( $t )
        docker tag $force "$tag" "$t"
        # Can't push multiple tags at once:
        # https://github.com/docker/docker/issues/7336
        push="$push; docker push '$t'"
    done
    cat <<EOF
Built: $tag
Channels: $build_version ${tags[*]}
EOF
    if [[ -n $build_push ]]; then
        for t in "${tags[@]}"; do
            echo "Pushing: $t"
            docker push "$t"
        done
    else
        cat <<EOF
To run it, you can then:

    docker run --rm -i -t '$tag'

After some testing, push the alpha channel:

    $push
EOF
    fi
}

build_image_clean() {
    if ! build_image_exists "$build_image_name"; then
        return 0
    fi
    local images=$build_image_exists
    local f=
    # Remove any exited containers.
    for f in $(docker ps -a --filter status=exited \
            | perl -n -e "m{^(\w+)\s.*\s\Q$build_image_name\E[\s:]} && print(qq{\$1\n})"); do
        docker rm "$f"
    done
    for f in $images; do
        # OK if a image is running, will be cleaned up next build
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
    if [[ ! -f /root/.bash_profile ]]; then
        cp -a /etc/skel/.??* /root
    fi
    build_create_run_user
    # Always overwrite with latest
    local run=/radia-run
    cat > "$run" <<EOF
#!/usr/bin/env python
#
# Adjust uid and gid of $build_run_user to match uid and gid
# of host user. This allows us to run as $build_run_user
# instead of root.
#
from __future__ import print_function
import os, pwd, sys, subprocess
user='$build_run_user'
if sys.argv < 4:
    print('usage: {} <uid> <gid> <absolute-path> <arg>...', file=sys.stderr)
    sys.exit(1)
cmd = sys.argv[1:]
uid = int(cmd.pop(0))
gid = int(cmd.pop(0))
p = pwd.getpwnam(user)
if p.pw_uid != uid:
    subprocess.check_call(['usermod', '-u', str(uid), user])
if p.pw_gid != gid:
    subprocess.check_call(['groupmod', '-g', str(gid), user])
    subprocess.check_call(['chgrp', '-R', str(gid), p.pw_dir])
#TODO(robnagler) look up groups. This is fine for now, because
# docker doesn't have any other groups for vagrant
os.setgroups([])
os.setgid(gid)
os.setuid(uid)
os.environ['HOME'] = p.pw_dir
assert os.path.isabs(cmd[0]), \
    '{}: command must be an absolute path'.format(cmd[0])
os.execv(cmd[0], cmd)
EOF
    chmod 555 "$run"
}
