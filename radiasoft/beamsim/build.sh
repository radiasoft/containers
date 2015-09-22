#!/bin/bash
build_image_base=fedora:21

run_as_root() {
    : n/a
}

run_as_exec_user() {
    cd
    # This line stops a warning from the pyenv installer
    bivio_path_insert ~/.pyenv/bin 1
    bivio_pyenv_2
    local v=$(cat ~/.pyenv/version)
    rm -f ~/.pyenv/version
    pyenv virtualenv "$v" py2
    pyenv local py2
    pyenv activate py2
    cd "$build_guest_conf"
    pip install -r requirements.txt
    . ./codes.sh
}
