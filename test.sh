#!/bin/bash
. ~/.bashrc
set -euo pipefail
cd ~/src
trap 'echo FAILED: err trap' ERR
cd radiasoft
gcl download
gcl container-test
if ! timeout 1 bash -c '</dev/tcp/127.0.0.1/2916'; then
    rm -f index.sh
    ln -s -r radiasoft/download/bin/index.sh .
    python3 -m http.server 2916 >& /dev/null&
    trap "kill $!" EXIT
fi
export install_server=http://$(dig $(hostname -f) +short):2916
# assumes radia_run: curl $install_server/index.sh | bash -s unit-test arg1
cd container-test
export radiasoft_secret_test=some-big-secret-xyzzy
build_passenv=radiasoft_secret_test radia_run container-build
img=radiasoft/test
ver=$(
    docker images |
        perl -n -e '!$x && m{^'"$img"'\s+(\d+\.\d+)} && print($x=$1)'
)
out=$(docker run --rm -u vagrant $img:$ver /home/vagrant/bin/radia-run-testimage 2>&1)
if [[ $out =~ radiasoft_secret_test || $out =~ $radiasoft_secret_test ]]; then
    echo "environment contains secret or variable name: $out" 1>&2
    exit 1
fi
if [[ ! $out =~ $ver ]]; then
    echo "$ver: version didn't appear in out: $out" 1>&2
    exit 1
fi
echo PASSED
