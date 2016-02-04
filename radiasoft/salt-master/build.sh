#!/bin/bash
build_fedora_base_image 23

build_as_root() {
    # We don't want any default config. Set by the runner
    rm -rf /etc/salt
    ln -s /vagrant/etc/salt /etc/salt
}
