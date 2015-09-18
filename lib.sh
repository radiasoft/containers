#!/bin/bash
#
# Usage: $0 image/name
# $0 is either docker/build.sh or vagrant/build.sh
#
# image/name is a subdirectory of the current working directory. The
# script "build.sh" must reside in image/name, and define the following:
#
# $build_image_base - starting image name
# run_as_root() - executed in $build_guest_conf on the guest as root
# run_as_exec_user() - executed after above as $build_exec_user
#
# Optionally define:
#
# $build_maintainer - default: RadiaSoft <docker@radiasoft.net>
#

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

    local systemd=
    if ps 1 | grep -s -q /systemd/; then
        # journald: stop until everything cleared
        systemd=1
        systemctl stop systemd-journald
    fi

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

    if [[ $systemd ]]; then
        # journald: config for small logs and start
        perl -pi -e 's/^#(RuntimeMaxUse=|SystemMaxUse=)/${1}1M/' \
             /etc/systemd/journald.conf
        systemctl start systemd-journald
    fi
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
    build_image_name=$1
    if ! [[ $build_image_name =~ ^([-_[:alnum:]]+)/([-_[:alnum:]]+)$ ]]; then
        build_err "$build_image_name: invalid or missing image/name\nusage: $0 <image/name>\n  -- <image/name> must be a directory"
    fi
    build_image_name_as_file=${BASH_REMATCH[1]}-${BASH_REMATCH[2]}
    build_script=$build_image_name/build.sh
    if [[ ! -f $build_script ]]; then
        build_err "$build_script: missing config file in current directory."
    fi
    build_host_conf=$(cd "$build_image_name"; pwd)

    . "./$build_script"

    local v=
    for v in build_image_base; do
        if [[ ! -v $v ]]; then
            build_err "\$$v: variable must defined in $build_script"
        fi
    done
    : ${build_maintainer:='RadiaSoft <docker@radiasoft.net>'}
    build_exec_user=vagrant
    for v in run_as_root run_as_exec_user; do
        if ! declare -f "$v" >& /dev/null; then
            build_err "$v(): function must be defined in $build_script"
        fi
    done

    if ! build_image_exists "$build_image_base"; then
        build_err "$build_image_base: image not found"
    fi

    build_init

    build_version=$(date -u +%Y%m%d.%H%M%S)
    build_dir=${TMPDIR-/var/tmp}/$build_image_name_as_file-$build_version
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
build_exec_user='$build_exec_user'
build_maintainer='$build_maintainer'
build_image_name='$build_image_name'
build_image_base='$build_image_base'
build_version='$build_version'
. "$build_guest_script"
build_run
EOF
    } > build-run.sh
    chmod +x build-run.sh

    build_run="$build_guest_conf/build-run.sh"
    build_image
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
