#!/bin/bash
build_image_base=radiasoft/beamsim

build_as_root() {
    rm -rf /etc/rabbitmq
    ln -s /vagrant /etc/rabbitmq
    curl -s -S -L https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/rabbitmq_v3_6_0/bin/rabbitmqadmin > /usr/bin/rabbitmqadmin
    chmod 555 /usr/bin/rabbitmqadmin
}

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
    # Install latest srw
    build_curl radia.run | bash -s containers/radiasoft/beamsim srw openPMD
    # Patch srwlib.py to not print stuff
    perl -pi.bak -e  's/^(\s+)(print)/$1pass#$2/' ~/.pyenv/versions/2.7.10/lib/python2.7/site-packages/srwlib.py
}
