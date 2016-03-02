#!/bin/bash
codes_dependencies common
codes_yum install fftw2-devel
codes_dependencies mpi4py
#Too slow. git repo has too much junk:
#   codes_download SRW
codes_download https://depot.radiasoft.org/foss/SRW-20160302.tar.gz
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
git clone https://github.com/ochubar/SRW
cd SRW
rm -rf .git literature env/{release,work/{install_proj,pre_releases,srw_igor,srw_python/data_example_*}}
find . -name '*.{old,a,so,pyd,lib,pdf}' -exec rm -f '{}' \;
cd ..
b=SRW-$(date +%Y%m%d)
mv SRW "$b"
tar czf "$b.tar.gz" "$b"
EOF
