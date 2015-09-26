#!/bin/bash
build_image_base=radiasoft/beamsim

run_as_exec_user() {
    cd
    pyenv activate
    cd "$build_guest_conf"
    local m
    for m in pykern sirepo; do
        git clone -q --depth 1 https://github.com/radiasoft/"$m"
        # Don't think we want an upgrade here, because might bring
        # in newer matplotlib or numpy. PyKern itself is ok to upgrade
        # always, because it will be backwards compatible.
        cd "$m"
        pip install -r requirements.txt
        python setup.py install
        cd ..
    done
    install -m 555 sirepo-in-docker.sh ~/bin/sirepo-in-docker
}
