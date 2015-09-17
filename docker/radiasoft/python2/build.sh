#!/bin/bash
build_tag_base=fedora:21

export PYENV_ROOT=/pyenv
python_version=2.7.10

run_as_root() {
    yum --color=never update -y
    yum --color=never install -y $(cat rpm-list.txt)
    mkdir "$PYENV_ROOT"
    chown vagrant:vagrant "$PYENV_ROOT"
}

run_as_vagrant() {
    export PATH="$PYENV_ROOT/bin:$PATH"
    curl -L -S -s https://raw.githubusercontent.com/radiasoft/pyenv-installer/master/bin/pyenv-installer | bash
    {
        echo "export PYENV_ROOT='$PYENV_ROOT'"
        cat <<'EOF'
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
# TODO: We don't need this
# eval "$(pyenv virtualenv-init -)"
EOF
    } >> ~/.bashrc
    eval "$(pyenv init -)"
    pyenv install "$python_version"
    pyenv global "$python_version"
    build_radiasoft_pykern
    pip install matplotlib
}
