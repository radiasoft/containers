#!/bin/bash
build_image_base=radiasoft/python2

build_as_run_user() {
    cd "$build_guest_conf"
    install -m 555 radia-run-rabbitmq.sh ~/bin/radia-run-rabbitmq
}
