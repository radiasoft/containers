#!/bin/bash
codes_dependencies pykern common-rpms
codes_download pypi-shadow3
pip install -r requirements.txt
python setup.py install
