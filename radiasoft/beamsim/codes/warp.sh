#!/bin/bash
codes_dependencies mpi4py Forthon h5py pygist
# May only be needed for diags in warp init warp_script.py
pip install python-dateutil
prev_pwd=$PWD
codes_download https://bitbucket.org/berkeleylab/warp.git
cd pywarp90
make clean install
cat > setup.local.py <<'EOF'
if parallel:
    import os, re
    r = re.compile('^-l(.+)', flags=re.IGNORECASE)
    for x in os.popen('mpifort --showme:link').read().split():
        m = r.match(x)
        if m:
            l = library_dirs if x[1] == 'L' else libraries
            l.append(m.group(1))
EOF
make FCOMP='-F gfortran --fcompexec mpifort' pclean pinstall
cd "$prev_pwd"
codes_download https://depot.radiasoft.org/foss/warp-initialization-tools-20160204.tar.gz
python setup.py install
