#!/bin/bash
build_vars() {
    build_image_base=radiasoft/beamsim
    boot_dir=$build_run_user_home/.radia-run
    tini_file=$boot_dir/tini
    radia_run_boot=$boot_dir/start
    build_docker_cmd='["'"$tini_file"'", "--", "'"$radia_run_boot"'"]'
    build_dockerfile_aux="USER $build_run_user"
}

build_as_run_user() {
    cd "$build_guest_conf"
    build_vars
    export notebook_dir=$build_run_user_home/jupyter
    export jupyterhub_singleuser=$boot_dir/jupyterhub-singleuser
    mkdir -p ~/.jupyter "$notebook_dir" "$boot_dir"
    cp jupyter_notebook_config.py ~/.jupyter
    perl -p -e 's/\{(\w+)\}/$ENV{$1} || die("$1: not found")/eg' radia-run.sh > "$radia_run_boot"
    chmod +x "$radia_run_boot"
    build_curl https://github.com/krallin/tini/releases/download/v0.9.0/tini > "$tini_file"
    chmod +x "$tini_file"
    build_curl https://raw.githubusercontent.com/jupyter/jupyterhub/master/scripts/jupyterhub-singleuser | perl -p -e 's/python3/python/' > "$jupyterhub_singleuser"
    #cp jupyterhub-singleuser.sh "$jupyterhub_singleuser"
    chmod +x "$jupyterhub_singleuser"
}

build_vars
