#!/bin/bash
build_image_base=radiasoft/beamsim

run_as_exec_user() {
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
    install -m 555 sirepo-in-docker.sh ~/bin/sirepo-in-docker
    ln -s /vagrant/RadTrack ~/RadTrack
    cat > ~/bin/radtrack-on-vagrant <<'EOF'
#!/bin/bash
cd ~/RadTrack
radtrack --beta-test < /dev/null 1>&2
EOF
    chmod +x ~/bin/radtrack-on-vagrant
}
