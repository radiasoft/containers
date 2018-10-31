#!/bin/bash
#
# Travis-CI support routines
#

build_travis_main() {
    if [[ ${TRAVIS_BRANCH:-} != master && ${TRAVIS_EVENT_TYPE:-} != push ]]; then
        build_msg 'Not a master push so skipping'
        return
    fi
    if [[ -z ${RADIASOFT_DOCKER_LOGIN:-} ]]; then
        build_err 'RADIASOFT_DOCKER_LOGIN must be defined'
    fi
    build_travis_setup_docker
    build_travis_setup_pypi
    export build_passenv="TRAVIS ${build_passenv:-}"
    export $build_passenv
    local noise_pid
    while true; do
        echo "$(date): some noise for travis"
        sleep 60
    done &
    noise_pid=$!
    build_main "$@"
    kill -9 "$noise_pid"
    build_travis_trigger_next
}

build_travis_setup_docker() {
    (
        umask 077
        mkdir ~/.docker
        # Avoid echoing in log if set -x
        perl -e 'print($ENV{"RADIASOFT_DOCKER_LOGIN"})' > ~/.docker/config.json
    )
    export build_push=1
    export build_batch_mode=1
}

build_travis_setup_pypi() {
    if ! [[ ${PKSETUP_PYPI_USER:-} && -r setup.py ]]; then
        return
    fi
    # Make sure some vars are defined that might not be
    : ${PKSETUP_PKDEPLOY_IS_DEV:=}
    : ${PKSETUP_PYPI_IS_TEST:=}
    export build_passenv='
        PKSETUP_PKDEPLOY_IS_DEV
        PKSETUP_PYPI_IS_TEST
        PKSETUP_PYPI_PASSWORD
        PKSETUP_PYPI_USER
        TRAVIS_BRANCH
        TRAVIS_COMMIT
    '
}

build_travis_trigger_next() {
    if [[ $@ ]]; then
        build_travis_trigger_next=( "$@" )
    fi
    if ! [[ ${build_travis_trigger_next:-} && ${RADIASOFT_TRAVIS_TOKEN:-} ]]; then
        return
    fi
    local r
    local sleep
    for r in "${build_travis_trigger_next[@]}"; do
        # Try to keep the order of the builds the same as in the list
        # Travis will get out of order if requests come in too quickly
        if [[ $sleep ]]; then
            sleep "$sleep"
        else
            sleep=15
        fi
        if [[ ! $r =~ / ]]; then
            r=radiasoft/container-$r
        fi
        build_msg "Travis Trigger: $r"
        local m=''
        if [[ ${TRAVIS_REPO_SLUG:-} && ${TRAVIS_COMMIT:-} ]]; then
            m=$(printf ',"message":"trigger %s@%s"' "$TRAVIS_REPO_SLUG" "$TRAVIS_COMMIT")
        fi
        local out=$(curl -s -S -X POST \
             -H 'Content-Type: application/json' \
             -H 'Accept: application/json' \
             -H 'Travis-API-Version: 3' \
             -H "Authorization: token $RADIASOFT_TRAVIS_TOKEN" \
             -d "$(printf '{"request": {"branch":"master"%s}}' "$m")" \
             "https://api.travis-ci.org/repo/${r/\//%2F}/requests" 2>&1 || true
        )
        if [[ ! $out =~ type.*pending ]]; then
            build_err "$r: travis trigger failed: $out"
        fi
    done
}
