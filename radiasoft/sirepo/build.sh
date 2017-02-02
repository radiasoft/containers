#!/bin/bash
build_image_base=radiasoft/beamsim

build_as_root() {
    umask 022
    build_curl https://rpm.nodesource.com/setup_4.x | bash
    yum install -y -q nodejs
}

build_as_run_user() {
    cd "$build_guest_conf"

    # Reinstall SRW
    build_curl radia.run | bash -s code srw
    # Patch srwlib.py to not print stuff
    local srwlib="$(python -c 'import srwlib; print srwlib.__file__')"
    # Trim .pyc to .py (if there)
    perl -pi.bak -e  's/^(\s+)(print)/$1pass#$2/' "${srwlib%c}"

    install -m 555 radia-run-sirepo.sh ~/bin/radia-run-sirepo

    # pykern
    git clone -q --depth 1 https://github.com/radiasoft/pykern
    cd pykern
    pip install -r requirements.txt
    python setup.py install
    cd ..

    # sirepo
    git clone -q --depth=50 "--branch=${TRAVIS_BRANCH-master}" \
        https://github.com/radiasoft/sirepo
    cd sirepo
    if [[ $TRAVIS_COMMIT ]]; then
        git checkout -qf "$TRAVIS_COMMIT"
    fi
    pip install -r requirements.txt
    python setup.py install

    # test & deploy
    # npm gets ECONNRESET due to a node error, which shouldn't happen
    # https://github.com/nodejs/node/issues/3595
    npm install jshint >& /dev/null || true
    bash test.sh
    cd ..
}
