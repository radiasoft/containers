#!/bin/bash
#
# Start juypterhub's single user init script with appropriate environment
# for radiasoft/beamsim.
#
cd
. ~/.bashrc

# must be after to avoid false returns in bashrc
set -e

curl radia.run | bash -s init-from-git radiasoft/jupyter.radiasoft.org "$JPY_USER/jupyter.radiasoft.org"

pyenv activate '{jupyter_venv}'

cd '{notebook_dir}'

if [[ -n $RADIA_RUN_CMD ]]; then
    # Can't quote this
    exec $RADIA_RUN_CMD
else
    # POSIT: 8888 in various jupyterhub repos
    exec jupyterhub-singleuser \
      --port="${RADIA_RUN_PORT:-8888}" \
      --ip=0.0.0.0 \
      --user="$JPY_USER" \
      --cookie-name="$JPY_COOKIE_NAME" \
      --base-url="$JPY_BASE_URL" \
      --hub-prefix="$JPY_HUB_PREFIX" \
      --hub-api-url="$JPY_HUB_API_URL" \
      --notebook-dir='{notebook_dir}'
    RADIA_RUN_CMD=$(type -f jupyterhub-singleuser)
fi

echo "ERROR: '$RADIA_RUN_CMD': exec failed'" 1>&2
exit 1
