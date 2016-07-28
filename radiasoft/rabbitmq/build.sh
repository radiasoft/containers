#!/bin/bash
rabbitmq_release=3_6_3
build_image_base=rabbitmq:${rabbitmq_release//_/.}
build_simply=1
build_docker_cmd='[]'
build_dockerfile_aux='ENTRYPOINT []'

build_script_host_init() {
    build_curl https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/rabbitmq_v"$rabbitmq_release"/bin/rabbitmqadmin > "$build_host_conf/rabbitmqadmin"
}

build_as_root() {
    rm -rf /etc/rabbitmq
    ln -s /vagrant /etc/rabbitmq
    local b=/usr/bin/rabbitmqadmin
    mv "$build_guest_conf/rabbitmqadmin" "$b"
    chmod 555 "$b"
    build_create_run_user
}
