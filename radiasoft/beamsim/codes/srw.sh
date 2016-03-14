#!/bin/bash
codes_dependencies common
codes_yum install fftw2-devel
codes_dependencies mpi4py
#Too slow. git repo has too much junk:
#   codes_download SRW
codes_download https://depot.radiasoft.org/foss/SRW-20160314.tar.gz
perl -pi -e 's/-j8//' Makefile
perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
make
d=$(python -c 'import distutils.sysconfig as s; print s.get_python_lib()')
(
    cd env/work/srw_python
    install -m 644 {srwl,uti}*.py srwlpy.so "$d"
)

: bash -l <<'EOF'
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
EOF
