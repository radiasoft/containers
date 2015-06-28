#!/bin/bash
# Copyright (c) 2015 RadiaSoft LLC.  All Rights Reserved.
#
# Install the user which runs RadTrack
#
set -e

. "$build_env"

. ~/.bashrc

cat > ~/bin/sirepo-in-docker <<'EOF'
#!/bin/bash
set -e
run_dir=$1
port=$2
. ~/.bashrc
cd ~/src/radiasoft/sirepo
pyenv activate
export PYTHONUNBUFFERED=1
mkdir -p "$run_dir"
cd "$run_dir"
sirepo service uwsgi --run-dir "$run_dir" --port "$port" --docker >& start.log
EOF
chmod +x ~/bin/sirepo-in-docker

cd ~/src/radiasoft
pyenv activate

# Update pykern
cd pykern
git pull
python setup.py develop
cd ../pykern

# Install sirepo
gcl sirepo
cd sirepo
python setup.py develop
