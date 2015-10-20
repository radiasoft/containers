#!/bin/sh
#
# Runs inside docker container as root
#
set -e
mkdir -p "$HTTPD_ROOT"/cgi-bin
install -m 400 /cfg2/index.html "$HTTPD_ROOT"/index.html
install -m 500 /cfg2/hello-world.cgi "$HTTPD_ROOT"/cgi-bin/hello-world
chgrp -R "$HTTPD_USER" "$HTTPD_ROOT"
chmod -R g+rX,a-w "$HTTPD_ROOT"
# We need to make sure /cfg/hello-world.sh is world executable, since
# the httpd will be running as non-root, but my-app ran as root (docker default).
# It's not recursive like above, because we are only as permissive
# as we need to be.
chgrp "$HTTPD_USER" /cfg /cfg/hello-world.sh
chmod g+x /cfg
chmod g+rx /cfg/hello-world.sh
