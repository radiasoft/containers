#!/bin/bash
if [[ $build_is_docker ]]; then
    build_image_base=fedora:21
else
    build_image_base=hansode/fedora-21-server-x86_64
fi

run_as_exec_user() {
    cd
    # This line stops a warning from the pyenv installer
    bivio_path_insert ~/.pyenv/bin 1
    bivio_pyenv_2
    . ~/.bashrc
    mkdir py2
    cd py2
    cp -a "$build_guest_conf"/requirements.txt .
    bivio_pyenv_local
    mv .python-version ~
    cd "$build_guest_conf"
    rm -rf ~/py2
    # Remove global version
    rm -f ~/.pyenv/version
}
