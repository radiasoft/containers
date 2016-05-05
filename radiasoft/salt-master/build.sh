#!/bin/bash
build_fedora_base_image 23

build_as_root() {
    # Everything has to be public
    umask 022
#docker run -it -u vagrant -p 4505-4506 -v /etc/salt:/etc/salt -v /var/cache/salt:/var/cache/salt -v /run/salt:/run/salt -v /srv:/srv -v /var/log/salt:/var/log/salt radiasoft/salt-master
    build_curl https://bootstrap.saltstack.com | bash -s -- -P -M -X -N -d -Z -n git develop
    # We don't want any default config, which is set by the runner
    rm -rf /etc/salt /var/cache/salt /srv
}
