#!/bin/bash
codes_dependencies pykern common
codes_download robnagler/shadow3
# requirements already satisfied, and there is a version conflict with
# the pip install -U in requirements.txt.
echo '#' > requirements.txt
python setup.py install
