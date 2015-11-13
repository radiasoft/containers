#!/bin/bash
build_fedora_base_image

build_as_run_user() {
    if [[ $build_is_vagrant ]]; then
        sudo rpm --import https://yum.dockerproject.org/gpg
        sudo cp docker.repo /etc/yum.repos.d/docker.repo
        build_yum install docker-engine
        sudo usermod -a -G docker vagrant
        sudo systemctl enable docker.service
    fi
    cd
    # This line stops a warning from the pyenv installer
    bivio_path_insert ~/.pyenv/bin 1
    . ~/.bashrc
    bivio_pyenv_2
    . ~/.bashrc
    pip install --upgrade pip
}
