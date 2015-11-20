#!/bin/bash
#
# See ./build for usage
#

build_image_add='docker pull'

build_clean() {
    if [[ $build_sudo_remove ]]; then
        rm -f "$build_sudo_remove"
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
    local alpha=$build_image_name:alpha
    local latest=$build_image_name:latest
    local dev=$build_image_name:dev
    docker build --rm=true --tag="$tag" .
    # We have to tag latest, because docker pulls that on
    # builds if you don't specify a version. Since build_image_base
    # is without a version, we are always building with latest.
    docker tag -f "$tag" "$latest"
    # Convenient tagging. We don't push
    docker tag -f "$tag" "$dev"
    docker tag -f "$tag" "$alpha"
    # Can't push multiple tags at once:
    # https://github.com/docker/docker/issues/7336
    cat <<EOF
Built: $tag
Tags: $build_version, latest, dev, alpha

To run it, you can then:

    docker run --rm -i -t '$tag'

After some testing, push the alpha channel:

    docker push '$tag'; docker push '$latest'; docker push '$alpha'
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
    if [[ ! -f /root/.bash_profile ]]; then
        cp -a /etc/skel/.??* /root
    fi
    if ! id -u $build_run_user >& /dev/null; then
        groupadd -g "$build_run_uid" "$build_run_user"
        useradd -m -g "$build_run_user" -u "$build_run_uid" "$build_run_user"
    fi
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
    local x=/etc/sudoers.d/$build_run_user
    if [[ ! -f $x ]]; then
        if [[ ! -x /usr/bin/sudo ]]; then
            build_yum install sudo
        fi
        echo "$build_run_user ALL=(ALL) NOPASSWD: ALL" > "$x"
        chmod 440 "$x"
        # Only needed for the build, removed after
        build_sudo_remove=$x
    fi
}
