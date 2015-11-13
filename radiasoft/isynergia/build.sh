#!/bin/bash
build_image_base=radiasoft/beamsim

build_as_run_user() {
    cd "$build_guest_conf"
    #!/bin/bash
    rm -rf ~/.ipython
    cp -a dot-ipython ~/.ipython
    cp -a job_manager.py ~/.pyenv/versions/2.7.10/lib/synergia_workflow/job_manager.py
    ipython -c '%install_ext https://raw.githubusercontent.com/rasbt/watermark/master/watermark.py'
    pip install tables
    install -m 555 radia-run-synergia.sh ~/bin/radia-run-synergia
}
