#!/bin/bash
build_fedora_base_image

build_as_run_user() {
    if [[ $build_is_vagrant ]]; then
        build_sudo rpm --import https://yum.dockerproject.org/gpg
        build_sudo cp docker.repo /etc/yum.repos.d/docker.repo
        build_yum install docker-engine
        build_sudo usermod -a -G docker vagrant
        build_sudo systemctl enable docker.service
    fi
    cd
    # Need to have requirements.txt for bivio_pyenv_2 to work
    touch requirements.txt
    # This line stops a warning from the pyenv installer
    bivio_path_insert ~/.pyenv/bin 1
    . ~/.bashrc
    bivio_pyenv_2
    . ~/.bashrc
    rm requirements.txt
    pip install --upgrade pip
    pip install --upgrade setuptools tox
    pyenv virtualenv py2
    pyenv global py2
}
