#!/bin/bash
build_fedora_base_image 23

build_as_root() {
    build_curl https://bootstrap.saltstack.com | bash -s -- -P -M -X -N -d -Z -n git develop
    # We don't want any default config, which is set by the runner
    rm -rf /etc/salt /var/cache/salt /srv
}
