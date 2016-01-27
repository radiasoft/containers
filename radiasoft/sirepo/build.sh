#!/bin/bash
build_image_base=radiasoft/beamsim

build_as_run_user() {
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
    install -m 555 radia-run-sirepo.sh ~/bin/radia-run-sirepo
    # Patch srwlib.py to not print stuff
    perl -pi.bak -e  's/^(\s+)(print)/$1#$2/' ~/.pyenv/versions/2.7.10/lib/python2.7/site-packages/srwlib.py
}
