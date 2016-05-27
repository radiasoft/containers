#!/bin/bash
build_image_base=jupyterhub/jupyterhub:0.6
build_simply=1
build_docker_cmd='[]'

build_as_root() {
    apt-get -y install python-psycopg2
    pip install 'ipython[all]'
    pip install git+git://github.com/jupyterhub/oauthenticator.git
    pip install git+git://github.com/jupyterhub/dockerspawner.git
    echo '# Real cfg in conf/jupyterhub_config.py' > /srv/jupyterhub/jupyterhub_config.py
    # Convenient to have "vagrant" user for development
    build_create_run_user
    apt-get clean
    rm -rf /var/lib/apt/lists/*
}
