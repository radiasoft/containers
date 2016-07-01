#!/bin/bash
#
# Install codes into containers. The code installation scripts reside in
# You can install individual codes (and dependencies) with:
#
# git clone https://github.com/radiasoft/containers
# cd containers/radiasoft/beamsim
# bash -l codes.sh <code1> <code2>
# pyenv rehash
#
# A list of available codes can be found in "codes" subdirectory.
#
set -e

# Build scripts directory
: ${CODES_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)/codes}

# Where to install binaries (needed by genesis.sh)
codes_bin_dir=$(dirname "$(pyenv which python)")

# Where to install binaries (needed by genesis.sh)
codes_lib_dir=$(python -c 'from distutils.sysconfig import get_python_lib as x; print x()')

# Avoids dependency loops
declare -A codes_installed

codes_curl() {
    curl -s -S -L "$@"
}

codes_dependencies() {
    codes_install_loop "$@"
}

codes_download() {
    # If download is an rpm, also installs
    local repo=$1
    local commit=$2
    if [[ ! $repo =~ / ]]; then
        repo=radiasoft/$repo
    fi
    if [[ ! $repo =~ ^(ftp|https?): ]]; then
        repo=https://github.com/$repo.git
    fi
    codes_msg "Download: $repo"
    case $repo in
        *.git)
            local d=$(basename "$repo" .git)
            if [[ $commit ]]; then
                git clone -q "$repo"
                cd "$d"
                git checkout "$commit"
            else
                git clone -q --depth 1 "$repo"
                cd "$d"
            fi
            ;;
        *.tar\.gz)
            local b=$(basename "$repo" .tar.gz)
            local t=tarball-$RANDOM
            codes_curl -o "$t" "$repo"
            tar xzf "$t"
            rm -f "$t"
            # It may unpack into a different directory (genesis does)
            if [[ -d $b ]]; then
                cd "$b"
            fi
            ;;
        *.rpm)
            local b=$(basename "$repo")
            # FRAGILE: works for current set of RPMs
            if rpm --quiet -q "${b//-*/}"; then
                echo "$b already installed"
            else
                codes_yum install "$repo"
            fi
            ;;
        *)
            codes_msg "$repo: unknown repository format; must end in .git, .rpm, .tar.gz"
            return 1
            ;;
    esac
    return 0
}

codes_install() {
    local sh=$1
    local module=$(basename $sh .sh)
    if [[ ${codes_installed[$module]} ]]; then
        return 0
    fi
    codes_installed[$module]=1
    local prev=$(pwd)
    local dir=${TMPDIR:-/var/tmp}/codes-$module-$UID-$RANDOM
    rm -rf "$dir"
    mkdir "$dir"
    if [[ ! -f $sh ]]; then
        # Might be passed as 'genesis', 'genesis.sh', 'codes/genesis.sh', or
        # (some special name) 'foo/bar/code1.sh'
        sh=$CODES_DIR/$module.sh
    fi
    codes_msg "Build: $module"
    codes_msg "Directory: $dir"
    cd "$dir"
    . "$sh"
    cd "$prev"
    rm -rf "$dir"
}

codes_install_loop() {
    local f
    for f in "$@"; do
        codes_install "$f"
    done
}

codes_main() {
    local -a codes=$@
    if [[ ! $codes ]]; then
        codes=( "$CODES_DIR"/*.sh )
    fi
    codes_install_loop "${codes[@]}"
}

codes_msg() {
    echo "$@" 1>&2
}

codes_yum() {
    codes_msg "yum $@"
    sudo yum --color=never -y -q "$@"
    if [[ -n $(type -p package-cleanup) ]]; then
        sudo package-cleanup --cleandupes
    fi
}

if [[ $0 == ${BASH_SOURCE[0]} ]]; then
    # Run independently from the shell
    if [[ ! $(cat /etc/fedora-release 2>/dev/null) =~ release.21 ]]; then
        codes_msg 'Only Fedora 21 is supported at this time'
        exit 1
    fi
    # make sure pyenv loaded
    if [[ $(type -t pyenv) != function ]]; then
        if [[ ! $(type -f pyenv 2>/dev/null) =~ /bin/pyenv$ ]]; then
            codes_msg 'ERROR: You must have pyenv in your path'
            exit 1
        fi
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    fi
    codes_main "$@"
else
    codes_main
fi
