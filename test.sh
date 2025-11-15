#!/bin/bash
. ~/.bashrc
set -euo pipefail
_err() {
    echo "$@" 1>&2
    return 1
}

trap '_err FAIL' ERR
export install_server=http://127.0.0.1:2916
if ! timeout 1 bash -c '</dev/tcp/127.0.0.1/2916'; then
    _err "start download/installers/rpm-code/dev-server.sh or similar"
fi
# assumes radia_run: curl $install_server/index.sh | bash -s unit-test arg1
cd ~/src/radiasoft/container-test
export GITHUB_TOKEN=some-big-secret-xyzzy
export GITHUB_PASSWORD=secret-pass
build_passenv=GITHUB_PASSWORD radia_run container-build
img=radiasoft/test
ver=$(
    docker images |
        perl -n -e '!$x && m{^'"$img"'\s+(\d+\.\d+)} && print($x=$1)'
)
out=$(docker run --rm -u vagrant $img:$ver /home/vagrant/bin/radia-run-testimage 2>&1)
if [[ $out =~ GITHUB_TOKEN || $out =~ $GITHUB_TOKEN ]]; then
    echo "environment contains secret or variable name: $out" 1>&2
    exit 1
fi
if [[ ! $out =~ $ver ]]; then
    _err "$ver: version didn't appear in out: $out" 1>&2
fi
rm -rf test-tmp
mkdir -p test-tmp
docker save $img:$ver | (cd test-tmp; tar xf -)
if grep -r -a "$GITHUB_TOKEN" test-tmp; then
    _err "deleted layer contains secret
cd $PWD"
fi
rm -rf test-tmp
echo PASSED
