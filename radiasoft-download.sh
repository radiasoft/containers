#!/bin/bash
#
# To run: curl radia.run | bash -s containers
#
containers_main() {
    install_script_eval bin/build.sh "$@"
}
