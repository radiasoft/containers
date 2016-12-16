#!/bin/bash

install_elegant_docs() {
    local elegant_docs=/usr/share/doc/elegant
    sudo mkdir -p "$elegant_docs"
    sudo chmod og+rx "$elegant_docs"
    sudo cp /conf/data/elegant/LICENSE $elegant_docs/LICENSE
    sudo cp /conf/data/elegant/defns.rpn $elegant_docs/defns.rpn
    sudo chmod -R ugo+r $elegant_docs
}

enable_rpn_defns() {
    local elegant_docs=/usr/share/doc/elegant
    cat > ~/.pyenv/pyenv.d/exec/rs-beamsim-elegant.bash <<EOF
#!/bin/bash
export RPN_DEFNS=$elegant_docs/defns.rpn
EOF
}

install_elegant_docs
enable_rpn_defns
codes_dependencies sdds
codes_download https://depot.radiasoft.org/foss/elegant-28.1.0-1.fedora.21.openmpi.x86_64.rpm
