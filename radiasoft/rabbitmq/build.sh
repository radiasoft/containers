#!/bin/bash
build_fedora_base_image

build_as_run_user() {
    cd "$build_guest_conf"
    install -m 555 sirepo-in-docker.sh ~/bin/sirepo-in-docker
}
