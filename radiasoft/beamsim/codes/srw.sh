#!/bin/bash
codes_dependencies common
codes_yum install fftw2-devel
codes_dependencies mpi4py

codes_download https://depot.radiasoft.org/foss/SRW-20160412.tar.gz
create_srw_tar_gz() {
    # Run this as root@apa11. We can't use SRW repo, because there's
    # too much historical data. The github pull code would be:
    #   codes_download SRW
    # This function outputs the codes_download line
    set -e
    if (( $UID != 0 )); then
        echo must be run as root
        exit 1
    fi
    if [[ ! -d ~/src/mrakitin ]]; then
        mkdir -p ~/src/mrakitin
    fi
    cd ~/src/mrakitin
    if [[ ! -d SRW ]]; then
        git clone https://github.com/mrakitin/SRW
    else
        cd SRW
        git checkout master
        git pull --all
        cd ..
    fi
    b=SRW-$(date +%Y%m%d)
    rsync -a --exclude .git SRW/. "$b"
    cd "$b"
    rm -rf literature env/{release,work/{install_proj,pre_releases,srw_igor,srw_python/{data_example_*,lib/*}}}
    find . -name '*.{old,a,so,pyd,lib,pdf}' -exec rm -f '{}' \;
    cd ..
    t=$b.tar.gz
    tar czf "$t" "$b"
    rm -rf "$b"
    x=$PWD/$t
    d=/var/www/virtualhost/depot/foss/$(basename "$x")
    mv "$x" "$d"
    chmod 444 "$d"
    echo "codes_download https://depot.radiasoft.org/foss/$t"
}

perl -pi -e 's/-j8//' Makefile
perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
make
d=$(python -c 'import distutils.sysconfig as s; print s.get_python_lib()')
(
    cd env/work/srw_python
    install -m 644 {srwl,uti}*.py srwlpy.so "$d"
)
