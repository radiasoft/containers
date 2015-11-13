#!/bin/bash
build_image_base=radiasoft/beamsim

build_as_run_user() {
    cd "$build_guest_conf"
    local m
    for m in pykern radtrack; do
        git clone -q --depth 1 https://github.com/radiasoft/"$m"
        # Don't think we want an upgrade here, because might bring
        # in newer matplotlib or numpy. PyKern itself is ok to upgrade
        # always, because it will be backwards compatible.
        cd "$m"
        if [[ $m == radtrack ]]; then
            bash install-pyqt4-fedora.sh
        fi
        pip install -r requirements.txt
        python setup.py install
        cd ..
    done
    ln -s /vagrant ~/RadTrack
    install -m 555 radia-run-radtrack.sh ~/bin/radia-run-radtrack
}
