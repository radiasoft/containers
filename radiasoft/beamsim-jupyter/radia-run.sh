#!/bin/bash
. ~/.bashrc

set -e

# "synergia" command sets up the environment this way so we have to, too
# Not clear if it will conflict with Warp or not
d=$(dirname "$(dirname "$(python -c 'import sys; sys.stdout.write(sys.executable)')")")/lib
export SYNERGIA2DIR=$d
export LD_LIBRARY_PATH=$d:/usr/lib64/openmpi/lib
export PYTHONPATH=$d

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

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
