#!/bin/bash
#
# Usage: $0 docker/tag
#
# docker/tag is a subdirectory of the current working directory. The
# script "build.sh" must reside in docker/tag, and define the following:
#
# $built_tag_base - name of docker base image
# run_as_root() - executed in $build_guest_conf on the guest as root
# run_as_vagrant() - executed after above as user vagrant
#
# Optionally define:
#
# $build_maintainer - default: RadiaSoft <docker@radiasoft.net>
#
build_bashrc() {
    local user=$(basename "$1")
    local bashrc=$1/.bashrc
    if ! grep -s -q TERM=dumb "$bashrc"; then
        local x=$(cat "$bashrc")
        printf "export TERM=dumb\n$x\n" > "$bashrc"
        chown "$user:$user" "$bashrc"
    fi
}

build_debug() {
    if [[ $build_debug ]]; then
        build_msg "$@"
    fi
}

build_err() {
    build_msg "$1"
    exit 1
}

build_fedora_clean() {
    # Caches
    yum clean all
    ls -d /var/cache/*/* | grep -v /var/cache/ldconfig/ | xargs rm -rf

    # journald: stop until everything cleared
    ### systemctl stop systemd-journald

    # Logs
    rm -f /var/log/{VBoxGuestAdditions,vboxadd}*.log
    for f in \
        sa \
        journal \
        anaconda \
        ; do
        rm -rf /var/log/"$f"/*
    done
    find /var/log \( -name '*20[0-9][0-9]*' -o -name '*.[0-9]' \) \
        -prune -exec rm -rf {} \;

    for f in \
        *.log \
        audit/audit.log \
        btmp \
        grubby \
        lastlog \
        wtmp \
        ; do
        if [[ -e /var/log/$f ]]; then
            cat /dev/null > /var/log/"$f"
        fi
    done

    # journald: config for small logs and start
    ### perl -pi -e 's/^#(RuntimeMaxUse=|SystemMaxUse=)/${1}1M/' /etc/systemd/journald.conf
    ### systemctl start systemd-journald

    # Tmp
    rm -rf /var/tmp/* /tmp/*

    # Doc
    rm -rf /usr/share/{man,info}

    # Locale
    # Locale is huge (+100MB) so compress. http://unix.stackexchange.com/a/90016
    # The original Fedora container does not have a locale-archive file, perhaps
    # that's right.
    localedef --list | grep -v -i ^en_US | xargs localedef --delete-from-archive
    mv /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
    build-locale-archive

    ls -d /usr/share/i18n/locales/* | grep -v en_US | xargs rm -rf
    ls -d /usr/share/i18n/charmaps/* | grep -v ISO-8859 | xargs rm -rf

    # User (vagrant) caches/junk
    rm -rf /home/*/.{cache,tox,python-eggs,*.old}
}

build_fedora_patch() {
    # Bug in this file that causes bashrc to "return"
    rm -f /etc/profile.d/colorzgrep.sh
    rm -f /etc/localtime
    # Not ideal, but where is the user really?
    ln -s /usr/share/zoneinfo/UCT /etc/localtime
}

build_main() {
    build_tag=$1
    if ! [[ $build_tag =~ ^([-_[:alnum:]]+)/([-_[:alnum:]]+)$ ]]; then
        build_err "$build_tag: invalid or missing docker tag\nusage: $0 <docker/tag>\n  -- <docker/tag> must be a directory"
    fi
    build_tag_as_file=${BASH_REMATCH[1]}-${BASH_REMATCH[2]}
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

    if ! build_image_exists "$build_tag_base" >/dev/null; then
        build_err "$build_tag_base: not in docker images -a"
    fi

    build_init

    build_version=$(date -u +%Y%m%d.%H%M%S)
    build_dir=${TMPDIR-/var/tmp}/$build_tag_as_file-$build_version
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
build_debug='$build_debug'
build_maintainer='RadiaSoft <docker@radiasoft.net>'
build_tag='$build_tag'
build_tag_base='$build_tag_base'
build_version='$build_version'
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
    local images=$(build_image_exists "$build_tag")
    if [[ ! $images ]]; then
        return 0
    fi
    local f=
    # Remove none running containers.
    for f in $(docker ps -a \
            | perl -n -e "m{^(\w+)\s.*\s\Q$build_tag\E[\s:]} && print(qq{\$1\n})"); do
        docker rm "$f"
    done
    for f in $images; do
        docker rmi "$f" 2>/dev/null || true
    done
}

build_image_exists() {
    local img=$1
    docker images -a | perl -ne "m{^${img/:/ +}\\b} && print((split)[2], qq{\\n})"
}

build_init() {
    set -e
    if [[ $build_debug ]]; then
        set -x
    fi
}

build_msg() {
    printf "$1\n" 1>&2
}

build_radiasoft_module() {
    local m=$1
    if [[ -d ~/src/radiasoft/$m ]]; then
        return 0
    fi
    local cmd=$2
    if [[ ! $cmd ]]; then
        cmd='pip install -r requirements.txt; pip install -e .;'
    fi
    (
        mkdir -p ~/src/radiasoft
        cd ~/src/radiasoft
        git clone --depth 1 https://github.com/radiasoft/"$m"
        cd "$m"
        eval $cmd
    )
    return $?
}

build_radiasoft_pykern() {
    build_radiasoft_module pykern
    return $?
}

build_run() {
    cd "$(dirname "$0")"
    build_init
    if [[ $UID == 0 ]]; then
        build_fedora_patch
        export HOME=/root
        build_user_root
        build_user_vagrant
        run_as_root
        # Run again, because of update or yum install may reinstall pkgs
        build_fedora_patch
        chown -R vagrant:vagrant .
        su vagrant "$0"
        build_fedora_clean
    else
        . ~/.bashrc
        run_as_vagrant
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
