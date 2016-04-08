#!/bin/bash
build_image_base=owncloud:latest

build_as_root() {
    chown -R "$build_run_user:$build_run_user" /var/www/html
    perl -pi -e 's/www-data/$build_run_user/; s/80/8080/' /etc/apache2/apache2.conf
    # Just in case this exists (see /usr/local/bin/apache2-foreground)
    rm -f /var/run/apache2/apache2.pid
}

build_as_run_user() {
    (
        cd /var/www/html
        tar cf - --one-file-system -C /usr/src/owncloud . | tar xf -
    )
}
