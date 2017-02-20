#!/bin/bash
#
# Travis-CI support routines
#

build_travis_main() {
    if [[ $TRAVIS_BRANCH != master && $TRAVIS_EVENT_TYPE != push ]]; then
        build_msg 'Not a master push so skipping'
        return
    fi
    if [[ -z $RADIASOFT_DOCKER_LOGIN ]]; then
        build_err 'RADIASOFT_DOCKER_LOGIN must be defined'
    fi
    build_travis_setup_docker
    build_travis_setup_pypi
    export build_passenv="TRAVIS $build_passenv"
    export $build_passenv
    build_main "$@"
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
    if ! [[ -n $PKSETUP_PYPI_USER && -r setup.py ]]; then
        return
    fi
    # "python setup.py --version" doesn't seem to work on travis so
    # this emulates what pkssetup.py does to get it from the git branch
    v=$(git log -1 --format=%ct "${TRAVIS_COMMIT:-$TRAVIS_BRANCH}")
    export build_version=$(python -c "import datetime as d; print d.datetime.fromtimestamp(float($v)).strftime('%Y%m%d.%H%M%S')")
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
    if ! [[ $build_travis_trigger_next && $RADIASOFT_TRAVIS_TOKEN ]]; then
        return
    fi
    local r
    for r in "${build_travis_trigger_next[@]}"; do
        if [[ ! $r =~ / ]]; then
            r=radiasoft/container-$r
        fi
        build_msg "Travis Trigger: $r"
        local out=$(curl -s -S -X POST \
             -H 'Content-Type: application/json' \
             -H 'Accept: application/json' \
             -H 'Travis-API-Version: 3' \
             -H "Authorization: token $RADIASOFT_TRAVIS_TOKEN" \
             -d '{"request": {"branch":"master"}}' \
             "https://api.travis-ci.org/repo/${r/\//%2F}/requests" 2>&1 || true
        )
        if [[ ! $out =~ type.*pending ]]; then
            build_err "$r: travis trigger failed: $out"
        fi
    done
}
