#!/bin/bash
build_image_base=fedora:21

export PYENV_ROOT=/pyenv
python_version=2.7.10

run_as_root() {
    cat >> /etc/NetworkManager/dispatcher.d/fix-slow-dns <<EOF
#!/bin/bash
# Fix slow DNS by updating resolve.conf
# http://fedoraforum.org/forum/showthread.php?t=238593
# https://github.com/mitchellh/vagrant/issues/1172#issuecomment-42263664
# https://github.com/chef/bento/blob/master/scripts/fedora/fix-slow-dns.sh
echo 'options single-request-reopen' >> /etc/resolv.conf
EOF
    chmod 550 /etc/NetworkManager/dispatcher.d/fix-slow-dns
    systemctl restart NetworkManager
    dd if=/dev/zero of=/swap bs=1M count=1024
    mkswap /swap
    chmod 600 /swap
    swapon /swap
    echo '/swap none swap sw 0 0' >> /etc/fstab
    perl -pi -e 's{^(X11Forwarding) no}{$1 yes}' /etc/ssh/sshd_config
    systemctl restart sshd.service
    # Containers are protected by their hosts
    (
        systemctl stop firewalld.service
        systemctl disable firewalld.service
    ) >& /dev/null || true
    # Remove the VirtualBox guest additions here so that the
    # initial boot on the client machines goes faster, since
    # these are surely the wrong version.
    local rpms=$(rpm -qa | grep VirtualBox || true)
    if [[ $rpms ]]; then
        # Remove the virtual box RPMs
        yum remove -y -q $rpms || true
    fi
    # https://bugzilla.redhat.com/show_bug.cgi?format=multiple&id=1171928
    # error: unpacking of archive failed on file /sys: cpio: chmod
    # error: filesystem-3.2-28.fc21.x86_64: install failed
    # DEBUG: Don't run update so comment this line:
    yum --color=never update -y --exclude='filesystem*'
    yum --color=never install -y $(cat rpm-list.txt)
    yum --color=never install -y https://get.docker.com/rpm/1.7.0/fedora-21/RPMS/x86_64/docker-engine-1.7.0-1.fc21.x86_64.rpm
}

run_as_exec_user() {
    mkdir -p .ssh
    if ! cmp -s "$build_guest_conf/authorized_keys" .ssh/authorized_keys; then
        cat "$build_guest_conf/authorized_keys" >> .ssh/authorized_keys
        chmod -R og-rwx .ssh
    fi
    # This line stops a warning from the pyenv installer
    bivio_path_insert ~/.pyenv/bin 1
    bivio_pyenv_2

    cd ~/src
    cp "$build_conf/requirements.txt" .
    bivio_pyenv_local
    mv .python-version ~

    build_radiasoft_pykern
    pip install matplotlib
}
