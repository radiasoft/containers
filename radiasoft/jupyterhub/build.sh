#!/bin/bash
build_image_base=jupyterhub/jupyterhub:0.7.0
build_simply=1
build_docker_cmd='[]'

build_as_root() {
    apt-get update
    apt-get -y install libpq-dev build-essential libffi-dev nginx-full libssl-dev build-essential
    pip install Psycopg2
    pip install 'ipython[all]'
    pip install git+git://github.com/jupyterhub/oauthenticator.git
    pip install git+git://github.com/jupyterhub/dockerspawner.git
    # pykern and pyasn1 are requirements for comsoljupyter but 
    # when installing from git sometimes pip throws a fit
    # installing manually the requirements helps with the issue
    pip install pyasn1
    pip install git+git://github.com/radiasoft/pykern@comsol-jupyter#egg=pykern
    pip install git+git://github.com/radiasoft/comsoljupyter#egg=comsoljupyter
    echo '# Real cfg in conf/jupyterhub_config.py' > /srv/jupyterhub/jupyterhub_config.py
    # Convenient to have "vagrant" user for development
    build_create_run_user
    apt-get clean
    rm -rf /var/lib/apt/lists/*
    rm -rf /root/.cache
    rm -rf /src
}
