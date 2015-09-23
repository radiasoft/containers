#!/bin/bash
build_image_base=radiasoft/python2

run_as_exec_user() {
    pyenv activate py2
    . ./codes.sh
}
