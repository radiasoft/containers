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
    build_yum install ffmpeg yum-utils texlive-scheme-medium
    # ffmpeg was already installed from rpmfusion, disable it for future packages
    yum-config-manager --disable 'rpmfusion*' > /dev/null
}

build_default_py2_kernel() {
    local where=( $(python -m ipykernel install --display-name 'Python 2' --name "$(pyenv global)" --user) )
    . ~/.pyenv/pyenv.d/exec/*synergia*.bash
    update_ipy_kernel_env "${where[-1]}"
}

build_synergia_pre3() {
    #TODO(robnagler) do this in radiasoft/beamsim/codes/synergia.sh
    #      need something to avoid hardwiring openmpi lib... PYTHONPATH is
    #      also not right, but we control everything here so probably ok.
    pip install -U 'git+git://github.com/radiasoft/rsbeams.git@master'
    pip install -U 'git+git://github.com/radiasoft/rssynergia.git@master'
    local venv=synergia-pre3
    pyenv virtualenv 2.7.10 "$venv"
    pyenv activate "$venv"
    # pykern brings in a lot of requirements to simplify build times
    pip install pykern
    build_curl radia.run | codes_synergia_branch=devel-pre3 bash -s master code synergia
    pip install -U 'git+git://github.com/radiasoft/rsbeams.git@master'
    pip install -U 'git+git://github.com/radiasoft/rssynergia.git@master'
    # http://ipython.readthedocs.io/en/stable/install/kernel_install.html
    # http://www.alfredo.motta.name/create-isolated-jupyter-ipython-kernels-with-pyenv-and-virtualenv/
    local where=( $(python -m ipykernel install --display-name 'Python 2 synergia-pre3' --name "$venv" --user) )
    . ~/.pyenv/pyenv.d/exec/*synergia*.bash
    update_ipy_kernel_env "${where[-1]}"
    # Test with: ipython notebook --no-browser --ip='*'
}

build_rsbeams_style() {
    cd /tmp
    git clone https://github.com/radiasoft/rsbeams
    for src in rsbeams/rsbeams/matplotlib/stylelib/*; do
        dst=~/.config/matplotlib/$(basename "$src")
        cp -a "$src" "$dst"
    done
    rm -rf rsbeams
}

build_jupyter() {
    # update python-build
    pyenv update || true

    local pyver=3.5.2

    pyenv install "$pyver"
    pyenv virtualenv "$pyver" "$jupyter_venv"
    pyenv activate "$jupyter_venv"

    pip install --upgrade pip
    pip install --upgrade setuptools
    # Since the Terminado Settings has not been merged into any release, we are have your
    # own fork with the changes applied to the latest release.
    pip install --upgrade --no-deps git+https://github.com/radiasoft/notebook@terminado_settings#egg=notebook
    pip install jupyter jupyterlab jupyterhub

    jupyter serverextension enable --py jupyterlab --sys-prefix
}

build_as_run_user() {
    cd "$build_guest_conf"
    build_vars
    local notebook_dir_base=jupyter
    export notebook_dir=$build_run_user_home/$notebook_dir_base
    export boot_dir
    export notebook_bashrc="$notebook_dir_base/bashrc"
    export notebook_template_dir="$boot_dir/$notebook_dir_base"
    export jupyter_venv=jupyter

    (build_jupyter)

    # POSIT: notebook_dir in salt-conf/srv/pillar/jupyterhub/base.yml
    mkdir -p ~/.jupyter "$notebook_dir" "$notebook_template_dir"
    build_replace_vars jupyter_notebook_config.py ~/.jupyter/jupyter_notebook_config.py
    build_replace_vars radia-run.sh "$radia_run_boot"
    chmod +x "$radia_run_boot"
    build_curl https://github.com/krallin/tini/releases/download/v0.9.0/tini > "$tini_file"
    chmod +x "$tini_file"
    local f
    for f in bashrc requirements.txt; do
        build_replace_vars "$f" "$notebook_template_dir/$f"
    done
    build_replace_vars post_bivio_bashrc ~/.post_bivio_bashrc
    . ~/.bashrc

    (build_default_py2_kernel)
    (build_rsbeams_style)
    (build_synergia_pre3)
}

update_ipy_kernel_env() {
    local where="$1"
    perl -pi -e 'sub _e {join(qq{,\n},
            map(qq{  "$_": "$ENV{$_}"},
                qw(SYNERGIA2DIR LD_LIBRARY_PATH PYTHONPATH)))};
        s/^\{/{\n "env": {\n@{[_e()]}\n },/' "$where/kernel.json"
}

build_vars
