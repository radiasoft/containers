#!/bin/bash
set -e
docker rm --force jupyter-vagrant || true
docker rm --force jupyterhub || true
rm -rf run
mkdir -p run/{conf,{scratch,jupyterhub}/vagrant}
perl -p -e 's/\$([A-Z_]+)/$ENV{$1}/eg' test_jupyterhub_config.py > run/conf/jupyterhub_config.py
args=(
    --rm
    --tty
    --name jupyterhub
    -u root
    -p 8000:8000
    -v $PWD/run/conf:/srv/jupyterhub/conf
    -v $PWD/run/jupyterhub:/var/db/jupyterhub
    -v $PWD/run/scratch:/scratch/jupyterhub
    -v /run/docker.sock:/run/docker.sock
    radiasoft/jupyterhub
    jupyterhub -f /srv/jupyterhub/conf/jupyterhub_config.py
)
docker run "${args[@]}"
