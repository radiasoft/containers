#!/bin/bash
. ~/.bashrc

set -e
d=$(dirname "$(dirname "$(python -c 'import sys; sys.stdout.write(sys.executable)')")")
export SYNERGIA2DIR=$d
export LD_LIBRARY_PATH=$d
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LNGUAGE=en_US.UTF-8

# 8888 is hardwired everywhere. It should be JPY_IP and JPY_PORT
exec {jupyterhub_singleuser} \
  --port=8888 \
  --ip=0.0.0.0 \
  --user="$JPY_USER" \
  --cookie-name="$JPY_COOKIE_NAME" \
  --base-url="$JPY_BASE_URL" \
  --hub-prefix="$JPY_HUB_PREFIX" \
  --hub-api-url="$JPY_HUB_API_URL" \
  --notebook-dir='{notebook_dir}'
