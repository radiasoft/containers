#!/bin/bash
build_vars() {
    build_image_base=radiasoft/beamsim
    boot_dir=$build_run_user_home/.radia-run
    tini_file=$boot_dir/tini
    radia_run_boot=$boot_dir/start
    build_docker_cmd='["'"$tini_file"'", "--", "'"$radia_run_boot"'"]'
    build_dockerfile_aux="USER $build_run_user"
}

build_as_root() {
    # Add RPMFusion repo:
    # http://rpmfusion.org/Configuration
    build_yum install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-21.noarch.rpm
    build_yum install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-21.noarch.rpm
    # ffmpeg for matplotlib animations
    # yum-utils for yum repo management
    build_yum install ffmpeg yum-utils
    # ffmpeg was already installed from rpmfusion, disable it for future packages
    yum-config-manager --disable 'rpmfusion*' > /dev/null
}

build_synergia_pre3() {
    local base=radia-synergia2dir.bash
d=$(pyenv prefix)/lib
export SYNERGIA2DIR=$d
export LD_LIBRARY_PATH=$d:/usr/lib64/openmpi/lib
export PYTHONPATH=$d

TODO: do this in beamsim
    local abs=$build_run_user_home/.pyenv/pyenv.d/exec/$base
    mkdir -p "$(dirname abs)"
    cp "$base" "$abs"
    . "$abs"
    local venv=synergia-pre3
    pyenv virtualenv "$venv"
    pyenv activate --force "$venv"
    # Get requirements for installing
    pip install pykern
    build_curl radia.run | codes_synergia_branch=devel-pre3 bash -s code synergia
    # http://ipython.readthedocs.io/en/stable/install/kernel_install.html
    # http://www.alfredo.motta.name/create-isolated-jupyter-ipython-kernels-with-pyenv-and-virtualenv/
    local where=$(python -m ipykernel install --display-name 'Python2 (synergia-pre3)' --name "$venv" --user)
export SYNERGIA2DIR=$d
export LD_LIBRARY_PATH=$d:/usr/lib64/openmpi/lib
export PYTHONPATH=$d

    perl -pi -e 's/\{/{\n  "env": ["SYNERGIA2DIR": "'"$SYNERGIA2DIR"'"],/' "${where[-1]}/kernel.json"
    # Test with: ipython notebook --no-browser --ip='*'
}

build_as_run_user() {
    cd "$build_guest_conf"
    build_vars
    local notebook_dir_base=jupyter
    export notebook_dir=$build_run_user_home/$notebook_dir_base
    export jupyterhub_singleuser=$boot_dir/jupyterhub-singleuser
    export boot_dir
    export notebook_bashrc="$notebook_dir_base/bashrc"
    export notebook_template_dir="$boot_dir/$notebook_dir_base"
    # Make sure these are up to date, fixes we need (terminado_settings) only in dev version
    pip install -U 'git+git://github.com/jupyter/notebook.git@4e359c921fb503ba3782a67cbd5ed221b081a478'
    # POSIT: notebook_dir in salt-conf/srv/pillar/jupyterhub/base.yml
    mkdir -p ~/.jupyter "$notebook_dir" "$notebook_template_dir"
    replace_vars jupyter_notebook_config.py ~/.jupyter/jupyter_notebook_config.py
    replace_vars radia-run.sh "$radia_run_boot"
    chmod +x "$radia_run_boot"
    build_curl https://github.com/krallin/tini/releases/download/v0.9.0/tini > "$tini_file"
    chmod +x "$tini_file"
    # Needed to run jupyterhub-singleuser script
    # pip install -U git+git://github.com/jupyterhub/jupyterhub.git
    # build_curl https://raw.githubusercontent.com/jupyter/jupyterhub/master/scripts/jupyterhub-singleuser | perl -p -e 's/python3/python/' > "$jupyterhub_singleuser"
    build_curl https://raw.githubusercontent.com/jupyterhub/jupyterhub/d9d68efa55afb57d40c23257a2915aa1337aef92/scripts/jupyterhub-singleuser > "$jupyterhub_singleuser"
    chmod +x "$jupyterhub_singleuser"
    replace_vars post_bivio_bashrc ~/.post_bivio_bashrc
    local f
    for f in bashrc requirements.txt; do
        replace_vars "$f" "$notebook_template_dir/$f"
    done
    (build_synergia_pre3)
}

replace_vars() {
    local src=$1
    local dst=$2
    perl -p -e 's/\{(\w+)\}/$ENV{$1} || die("$1: not found")/eg' "$src" > "$dst"
}

build_vars
