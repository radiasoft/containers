#!/bin/bash
#
# Start juypterhub's single user init script with appropriate environment
# for radiasoft/beamsim.
#
cd
~/.bashrc
# must be after to avoid false returns in bashrc
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

cd '{notebook_dir}'
if ! diff '{boot_dir}'/requirements.txt requirements.txt >& /dev/null; then
    (
        set +e
        pip install --upgrade requirements.txt >& requirements.out
        # Don't track whether install is successful
        cp requirements.txt '{boot_dir}'
    )
fi


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
