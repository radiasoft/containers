#!/bin/bash
codes_dependencies mpi4py Forthon h5py pygist
# May only be needed for diags in warp init warp_script.py
pip install python-dateutil
prev_pwd=$PWD
codes_download https://bitbucket.org/berkeleylab/warp.git
git checkout 0755530ae90d8f68e1cacb86c105f57c68d2e63f
cd pywarp90
make clean install
cat > setup.local.py <<'EOF'
if parallel:
    import os, re
    r = re.compile('^-l(.+)', flags=re.IGNORECASE)
    for x in os.popen('mpifort --showme:link').read().split():
        m = r.match(x)
        if not m:
            continue
        arg = m.group(1)
        if x[1] == 'L':
             library_dirs.append(arg)
             extra_link_args += ['-Wl,-rpath', '-Wl,' + arg]
        else:
             libraries.append(arg)
EOF
make FCOMP='-F gfortran --fcompexec mpifort' pclean pinstall
cd "$prev_pwd"
codes_download https://depot.radiasoft.org/foss/warp-initialization-tools-20160204.tar.gz
python setup.py install
