#!/bin/bash
codes_dependencies common
codes_yum install fftw2-devel
codes_dependencies mpi4py
#Too slow. git repo has too much junk:
#   codes_download SRW
codes_download https://depot.radiasoft.org/foss/SRW-20160304.tar.gz
perl -pi -e 's/-j8//' Makefile
perl -pi -e "s/'fftw'/'sfftw'/" cpp/py/setup.py
perl -pi -e 's/-lfftw/-lsfftw/; s/\bcc\b/gcc/; s/\bc\+\+/g++/' cpp/gcc/Makefile
make
d=$(python -c 'import distutils.sysconfig as s; print s.get_python_lib()')
(
    cd env/work/srw_python
    install -m 644 {srwl,uti}*.py srwlpy.so "$d"
)

: Creating SRW*tar.gz <<'EOF'
cd ~/src/mrakitin
test -d SRW || git clone https://github.com/mrakitin/SRW
cd SRW
git checkout master
git pull --all
cd ..
b=SRW-$(date +%Y%m%d)
rsync -a --exclude .git SRW/. "$b"
cd "$b"
rm -rf literature env/{release,work/{install_proj,pre_releases,srw_igor,srw_python/{data_example_*,lib/*}}}
find . -name '*.{old,a,so,pyd,lib,pdf}' -exec rm -f '{}' \;
cd ..
tar czf "$b.tar.gz" "$b"
rm -rf "$b"
echo "x=$PWD/$b.tar.gz"
# As root
d=/var/www/virtualhost/depot/foss/$(basename "$x")
mv "$x" "$d"
chown root:root "$d"
chmod 444 "$d"
EOF
