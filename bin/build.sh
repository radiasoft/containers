#!/bin/bash
#
# Run from directory (repo) which has container-conf/build.sh
#
# cd ~/src/radiasoft/container-<name>
#
#     curl radia.run | bash -s containers [vagrant]
#
# or see radiasoft/download/README.md
#
#     install_server=http://$(dig $(hostname -f) +short):2916 bash -s container-build
#
# The script "build.sh" must define the following:
#
# $build_image_base - starting image name
# build_as_run_user() - executed after above as $build_run_user
#
# You can provide a build_push=1 environment variable to
# force the push to the registery (only works with docker).
#
# Optionally define:
#
# $build_batch_mode - defaults to false
# $build_passenv - variables to pass to containter
# $build_maintainer - identify author of image [RadiaSoft <(vagrant|docker)@radiasoft.net>]
# $build_vagrant_uri - for help message on how to install in vagrant hub [https://depot.radiasoft.org/foss]
# $build_version - defaults to the time now, but can be any chronological version
#
# You could, but probably don't want to change these:
#
# $build_run_user - application runs as this user [vagrant]
# $build_run_uid - application user is this uid [1000]
set -euo pipefail

build_start_dir=$(pwd)

: ${build_passenv:=}
: ${build_batch_mode:=}

build_as_root() {
    : Executes as root after root setup complete
}

build_as_run_user() {
    : Executes as build_run_user after root is built and home env setup
}

build_clean() {
    set +e
    trap - EXIT
    build_clean_container
    cd /
    if [[ ${build_dir:-} ]]; then
        rm -rf "$build_dir"
    fi
}

build_clean_as_root() {
    : Executes as root after build_as_run_user runs to allow removal of packages
}

build_create_run_user() {
    if ! id -u $build_run_user >& /dev/null; then
        groupadd -g "$build_run_uid" "$build_run_user"
        useradd -m -g "$build_run_user" -u "$build_run_uid" "$build_run_user"
    fi
}

build_curl() {
    curl -s -S -L "$@"
}

build_debug() {
    if [[ $build_debug ]]; then
        build_msg "$@"
    fi
}

build_dir_hook() {
    : Executes after build_dir is created, but before changing to directory.
}

build_err() {
    build_msg "$@"
    if [[ ${build_dir:-} && -d $build_dir ]]; then
        if [[ ! ${build_batch_mode:-} ]]; then
            echo "Directory: $build_dir"
            echo -n 'Type enter to destroy dir and container (or control-C to exit):'
            read
        fi
        build_clean
    fi
    exit 1
}

build_err_trap() {
    set +e
    trap - EXIT
    trap - ERR
    build_err "Build: ERROR TRAP"
}

build_fedora_base_image() {
    # Run outside the container
    declare v=${1:-$install_version_fedora}
    if [[ ${build_is_vagrant:-} ]]; then
#TODO(robnagler) remove vagrant support???
        build_image_base=fedora-$v
    else
        build_image_base=fedora:$v
    fi
}

build_fedora_version() {
    # Only run inside the container
    if [[ $install_os_release_id != fedora ]]; then
        build_err 'Not a Fedora release'
    fi
    echo "$install_os_release_version_id"
}

build_fedora_clean() {
    if [[ ${build_no_clean:-} ]]; then
        return
    fi
    # Clear caches
    build_yum clean all
    ls -d /var/cache/*/* | grep -v /var/cache/ldconfig/ | xargs rm -rf
    declare systemd=
    if ps 1 | grep -s -q /systemd/; then
        # journald: stop until everything cleared
        systemd=1
        systemctl stop systemd-journald || true
    fi
    # Logs
    rm -f /var/log/{VBoxGuestAdditions,vboxadd}*.log /radia-run-install.log
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
        systemctl start systemd-journald || true
    fi
    # Tmp
    rm -rf /var/tmp/* /tmp/*
    # Doc
    rm -rf /usr/share/{man,info}
    if [[ -e /usr/lib/locale/locale-archive ]]; then
        # Only for systems which have locale-archive. Fedora 25 does not.
        # Locales are huge (+100MB) so compress. http://unix.stackexchange.com/a/90016
        # Recreate with just what we need
        rm -f /usr/lib/locale/locale-archive /usr/lib/locale/locale-archive.tmpl
        localedef -c -i en_US -f UTF-8 en_US
        localedef -c -i en_US -f ISO-8859-1 en_US.iso88591
        localedef -c -i en_US -f ISO-8859-15 en_US.iso885915
        # Work around a bug in CentOS 6 or Docker 1.7 that doesn't deal with
        # files with holes correctly.
        dd if=/usr/lib/locale/locale-archive of=/usr/lib/locale/locale-archive-
        mv /usr/lib/locale/locale-archive- /usr/lib/locale/locale-archive
        chmod 644 /usr/lib/locale/locale-archive
    fi
    # This should recreate the archive, but there are missing charmaps and such
    # User (vagrant) caches and junk
    rm -rf /home/*/.{cache,tox,python-eggs,*.old,Xauthority}
}

build_fedora_patch() {
    # Bug in this file that causes bashrc to "return"
    rm -f /etc/profile.d/colorzgrep.sh
    rm -f /etc/localtime
    # Not ideal, but where is the user really?
    ln -s /usr/share/zoneinfo/UCT /etc/localtime
    if [[ -e /etc/dnf/dnf.conf ]] && ! grep -s -q 'color=never' /etc/dnf/dnf.conf; then
        echo 'color=never' >> /etc/dnf/dnf.conf
    fi
}

build_home_env() {
    declare update=~/bin/_bivio_home_env_update
    if [[ -x $update ]]; then
        # Need proper environment for update
        install_source_bashrc
        "$update" -f
    else
        install_repo_eval home
        if [[ $build_is_docker ]]; then
            echo 'export TERM=dumb' >> ~/.pre_bivio_bashrc
        fi
    fi
    install_source_bashrc
}

build_init() {
    set -e -o pipefail
    if [[ ${install_debug:-} ]]; then
        build_debug=1
    else
        : ${build_debug:=}
    fi
    if [[ $build_debug ]]; then
        if [[ ${BASH_SOURCE:-} ]]; then
            export PS4='+ [${BASH_SOURCE:+${BASH_SOURCE##*/}}:${LINENO}] '
        fi
        set -x
    fi
    # Can happen that libraries access X11. You'll see:
    # X11 connection rejected because of wrong authentication.
    export DISPLAY=
    build_init_type
    umask "$build_umask"
    # Modify the umask for home-env
    export BIVIO_UMASK=$(umask)
}

build_main() {
    trap build_err_trap EXIT
    build_main_args "$@"
    build_main_init
    build_image_prep
    build_main_conf_dir
    build_image
    build_clean
}

build_main_args() {
    build_type=${1:-}
    declare d=$(pwd)
    build_script=$d/container-conf/build.sh
    if [[ ! ${build_image_name:-} ]]; then
        declare b=$(basename "$d")
        if [[ $b =~ ^container-([-_[:alnum:]]+)$ ]]; then
            b=${BASH_REMATCH[1]}
        fi
        declare o=$(basename "$(dirname "$d")")
        build_image_name=$o/$b
    fi
    build_host_conf=$(cd "$(dirname "$build_script")"; pwd)
    if [[ ! $build_type ]]; then
        build_type=docker
    elif [[ ! $build_type =~ ^(vagrant|docker)$ ]]; then
        build_err 'usage: build [vagrant|docker (default)]'
    fi
    install_script_eval "bin/build-$build_type.sh"
}

build_main_init() {
    build_init_type
    : ${build_maintainer:="RadiaSoft <support@radiasoft.net>"}
    : ${build_vagrant_uri:=$(install_foss_server)}
    : ${build_version:=$(date -u +%Y%m%d.%H%M%S)}
    : ${build_umask:=022}
    # POSIT: same as download/installers/container-run/radiasoft-download.sh
    build_run_user=vagrant
    build_run_user_home=/home/$build_run_user
    build_run_uid=1000
    build_run_dir=/$build_run_user
    build_simply=
    source "$build_script"
    if [[ $(type -t build_script_host_init) == 'function' ]]; then
        build_script_host_init
    fi
    declare v=
    if [[ ! ${build_image_base:-} ]]; then
        build_err "build_image_base: variable must defined in $build_script"
    fi
    if [[ ! $build_version =~ ^[[:digit:]]{8}\.[[:digit:]]{6}$ ]]; then
        build_err "$build_version: build_version must be a cronver"
    fi
    for v in build_as_run_user; do
        if ! declare -f "$v" >& /dev/null; then
            build_err "$v(): function must be defined in $build_script"
        fi
    done
    build_init
    # Must be /var/tmp, because directory contains .vagrant info and
    # a reboot will delete $TMPDIR on Macs or /tmp on linux so
    # vagrant info is no longer there and hard to clean up.
    build_dir=/var/tmp/containers-$build_version-$RANDOM
    build_guest_conf=/rscontainers
    build_guest_script=$build_guest_conf/$(basename "$build_script")
    build_rsmanifest=/rsmanifest.json
    build_git_commit=$(git rev-parse HEAD 2>/dev/null || true)
    build_git_remote_origin_url=$(git config --get remote.origin.url 2>/dev/null || true)
    build_msg "Conf: $build_host_conf"
    build_msg "Build: $build_dir"
}

build_main_conf_dir() {
    rm -rf "$build_dir"
    mkdir "$build_dir"
    build_dir_hook
    cd "$build_dir"
    cp -a "$build_host_conf"/* .
    {
        echo '#!/bin/bash'
        for f in $(compgen -A function build_) $(compgen -A function install_); do
            declare -f "$f"
        done
        for f in $(compgen -A variable build_) $(compgen -A variable install_) $build_passenv; do
            declare -p "$f"
        done
        cat <<EOF
set -e
$(install_vars_export)
install_init_vars
source "$build_guest_script"
build_run
EOF
    } > build-run.sh
    chmod +x build-run.sh
    build_run="$build_guest_conf/build-run.sh"
}

build_msg() {
    echo "$@" 1>&2
}

build_replace_vars() {
    declare src=$1
    declare dst=$2
    perl -p -e 's/\{(\w+)\}/$ENV{$1} || die("$1: not found")/eg' "$src" > "$dst"
}

build_rsmanifest() {
    rm -f "$build_rsmanifest"
    cat <<EOF > "$build_rsmanifest"
{
    "image": {
        "git_commit": "$build_git_commit",
        "git_remote_origin_url": "$build_git_remote_origin_url",
        "name": "$build_image_name",
        "type": "$build_type",
        "uri": "$build_image_uri",
        "version": "$build_version"
    },
    "version": "20190612.150000"
}
EOF
    chmod 444 "$build_rsmanifest"
}

build_run() {
    cd "$(dirname "$0")"
    build_init
    if [[ $build_simply ]]; then
        build_run_dir
        build_sudo_install
        build_as_root
        build_sudo_remove
        build_rsmanifest
    elif (( $UID != 0 )); then
        build_home_env
        build_as_run_user
        return
    else
        build_run_yum
        build_sudo_install
        build_root_setup
        build_fedora_patch
        build_home_env
        build_run_dir
        build_as_root
        build_rsmanifest
        chown -R "$build_run_user:" "$build_guest_conf"
        su "$build_run_user" "$0"
        build_clean_as_root
        build_sudo_remove
        build_fedora_clean
    fi
    cd /
    if [[ $build_debug ]]; then
        mv -f "$build_guest_conf" "$build_guest_conf-$(date +%Y%m%d%H%M%S)"
    else
        rm -rf "$build_guest_conf"
    fi
}

build_run_dir() {
    # /vagrant may not exist so create it. synced_folder is disabled
    # by default with Vagrant to avoid guest additions loading problems.
    if [[ ! -d $build_run_dir ]]; then
        mkdir -p "$build_run_dir"
        if id "$build_run_user" >& /dev/null; then
            chown "$build_run_user:" "$build_run_dir"
        fi
    fi
}

build_run_yum() {
    declare f
    f=/etc/yum.repos.d/CentOS-Base.repo
    if install_os_is_centos_7 && ! grep baseurl=https://depot.radiasoft "$f" &> /dev/null; then
        sed -i.bak -e 's,^mirrorlist=http://mirrorlist,#mirrorlist=http://vault,' \
              -e 's,^#baseurl=http://mirror.centos.org,baseurl=https://depot.radiasoft.org/yum,' \
                "$f"
    fi
    # if the dnf-plugin-ovl isn't there, touch rpm db
    if [[ ! ${build_no_touch_rpmdb:-} ]]; then
        build_msg 'touch /var/lib/rpm/*'
        # Avoid corrupting rpm db
        # https://github.com/moby/moby/issues/10180#issuecomment-378005800
        # Tried dnf-plugin-ovl, but that did not work. This definitely works:
        touch /var/lib/rpm/*
    fi
    if [[ ${build_want_yum_update:-} ]]; then
        # https://bugzilla.redhat.com/show_bug.cgi?format=multiple&id=1171928
        # error: unpacking of archive failed on file /sys: cpio: chmod
        # error: filesystem-3.2-28.fc21.x86_64: install failed
        #
        # https://github.com/radiasoft/containers/issues/86
        # error: unpacking of archive failed on file /etc/hosts: cpio: rename failed - Device or resource busy
        # DEBUG: Don't run update so comment this line:
        build_yum update --exclude='filesystem*' --exclude='setup-*'
    fi
    # git, diffutils, and tar are needed to build home_env
    declare -a rpms=()
    for f in diffutils findutils git procps-ng sudo tar; do
        if ! rpm --quiet -q "$f"; then
            rpms+=($f)
        fi
    done
    for f in rpms.txt "rpms-$build_type.txt"; do
        if [[ -f $f ]]; then
            rpms+=( $(grep -v '^#' "$f" || true) )
        fi
    done
    if [[ $rpms ]]; then
        build_yum install "${rpms[@]}"
    fi
}

build_sudo() {
    declare sudo
    if [[ $UID != 0 ]]; then
        sudo=sudo
    fi
    ${sudo:-} "$@"
}

build_sudo_install() {
    if [[ ! -e /usr/bin/sudo ]]; then
        return
    fi
    chmod 4111 /usr/bin/sudo
    declare x=/etc/sudoers.d/$build_run_user
    if [[ -f $x ]]; then
        # Don't remove if installed in base image,
        # because likely vagrant.
        return
    fi
    echo "$build_run_user ALL=(ALL) NOPASSWD: ALL" > "$x"
    chmod 440 "$x"
    # Only needed for docker build, removed after
    build_sudo_remove=$x
}

build_sudo_remove() {
    if [[ ! -e /usr/bin/sudo ]]; then
        return
    fi
    chmod 111 /usr/bin/sudo
    if [[ -n $build_sudo_remove ]]; then
        rm -f "$build_sudo_remove"
    fi
}

build_yum() {
    declare cmd=( yum )
    if [[ $(type -t dnf) ]]; then
        cmd=( dnf )
    else
        build_sudo rpm --rebuilddb --quiet
    fi
    build_msg "${cmd[*]} $*"
    if [[ ! $build_debug ]]; then
        cmd+=( -q )
    fi
    build_sudo "${cmd[@]}" --color=never -y "$@"
    if [[ ${cmd[0]} = yum && -n $(type -p package-cleanup) ]]; then
        build_sudo package-cleanup --cleandupes
    fi
}

build_main ${install_extra_args[@]+"${install_extra_args[@]}"}
