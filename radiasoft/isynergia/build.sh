#!/bin/bash
build_image_base=radiasoft/beamsim

run_as_exec_user() {
    cd "$build_guest_conf"
    #!/bin/bash
    rm -rf ~/.ipython
    cp -a dot-ipython ~/.ipython
    cp -a job_manager.py ~/.pyenv/versions/2.7.10/lib/synergia_workflow/job_manager.py
    ipython -c '%install_ext https://raw.githubusercontent.com/rasbt/watermark/master/watermark.py'
    pip install tables
    cat <<'EOF' > bin/synergia-ipython-beamsim
#!/bin/bash
cd /vagrant
if [[ ! -d beamsim ]]; then
    git clone -q https://github.com/radiasoft/beamsim
fi
exec synergia --ipython notebook
EOF
    chmod +x bin/synergia-ipython-beamsim
}
