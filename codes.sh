#!/bin/bash
#
# Install codes into containers. The code installation scripts reside in
#
#
set -e

# Subdir where the codes are
: ${CODES_DIR:=codes}

# Where to install binaries (needed by genesis.sh)
codes_bin_dir=$(dirname "$(pyenv which python)")

# Avoids dependency loops
declare -A codes_sourced

codes_all() {
    local f
    set -e
    local names=
    for f in "$CODES_DIR"/*.sh; do
        codes_source "$f"
    done
}

codes_build() {
    local cmd=$1
    if [[ $cmd =~ \.sh$ ]]; then
        . ./$cmd
    else
        codes_download "$repo"
        if [[ $cmd ]]; then
            $cmd
        else
            # Install the requirements first
            if [[ -f requirements.txt ]]; then
                pip install --upgrade -r requirements.txt
            fi
            python setup.py install
        fi
    fi
    #TODO(robnagler) Do we want to store version somewhere?
    # commit=( $(git ls-remote https://github.com/radiasoft/$m master) )

}

codes_dependencies() {
    local deps=$@
    local d
    for d in $deps; do
        codes_source "$CODES_DIR/$d.sh"
    done
}

codes_download() {
    local repo=$1
    if [[ ! $repo =~ / ]]; then
        repo=radiasoft/$repo
    fi
    if [[ ! $repo =~ ^(ftp|https?): ]]; then
        repo=https://github.com/$repo.git
    fi
    if [[ $repo =~ \.git$ ]]; then
        git clone -q --depth 1 "$repo"
        cd "$(basename "$repo" .git)"
        return 0
    fi
    if [[ $repo =~ \.tar\.gz$ ]]; then
        local b=$(basename "$repo" "${BASH_REMATCH[0]}")
        local t=tarball-$RANDOM
        curl -o "$t" -S -s "$repo"
        tar xzf "$t"
        rm -f "$t"
        # It may unpack into a different directory (genesis does)
        if [[ -d $b ]]; then
            cd "$b"
        fi
        return 0
    fi
    codes_msg "$repo: unknown repository format; must end in .git or .tar.gz"
    return 1

}

codes_msg() {
    echo "$1" 1>&2
}

codes_source() {
    local sh=$1
    if [[ ${codes_sourced[$sh]} ]]; then
        return 0
    fi
    codes_sourced[$sh]=1
    local dir=${TMPDIR:/var/tmp}/codes-$(basename "$sh" .sh)-$UID-$RANDOM
    rm -rf "$dir"
    mkdir "$dir"
    (
        codes_msg "$(date) Build: $repo"
        codes_msg "Directory: $dir"
        set -e
        cd "$dir"
        . "./$sh"
    )
    local res=$?
    if [[ $res == 0 ]]; then
        rm -rf "$dir"
    fi
    codes_msg "ERROR: $repo build failed"
    return $?
}

codes_all
