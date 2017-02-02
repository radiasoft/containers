#!/bin/bash
set -e
trap 'echo FAILED' ERR
img=radiasoft/testimage
export radiasoft_secret_test=some-big-secret-xyzzy
export radiasoft_secret_test=some-big-secret-xyzzy
build_batch_mode=1 build_passenv=radiasoft_secret_test bin/build docker "$img"
ver=$(
    docker images |
        perl -n -e 'm{^'"$img"'\s+(\d+\.\d+)} && print($1) && exit(0)'
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
