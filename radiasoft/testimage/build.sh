#!/bin/bash
build_fedora_base_image

build_as_run_user() {
    cd "$build_guest_conf"
    if [[ $radiasoft_secret_test != some-big-secret-xyzzy ]]; then
        echo 'radiasoft_secret_testwas not included' 1>&2
        exit 1
    fi
    local test=~/bin/radia-run-testimage
    install -m 755 radia-run-testimage.sh "$test"
    cat >> "$test" <<EOF
if [[ -e $build_guest_conf ]]; then
    echo '$build_guest_conf is visible in container' 1>&2
    exit 1
fi
EOF
}
