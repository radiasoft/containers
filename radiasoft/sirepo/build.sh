#!/bin/bash
build_image_base=radiasoft/beamsim

build_as_run_user() {
    cd "$build_guest_conf"
    local m
    for m in pykern sirepo; do
        git clone -q --depth 1 https://github.com/radiasoft/"$m"
        cd "$m"
        pip install -r requirements.txt
        python setup.py install
        cd ..
    done
    install -m 555 radia-run-sirepo.sh ~/bin/radia-run-sirepo
    # Install latest srw
    build_curl radia.run | bash -s containers/radiasoft/beamsim srw
    # Patch srwlib.py to not print stuff
    local srwlib="$(python -c 'import srwlib; print srwlib.__file__')"
    # Trim .pyc to .py (if there)
    perl -pi.bak -e  's/^(\s+)(print)/$1pass#$2/' "${srwlib%c}"
}
