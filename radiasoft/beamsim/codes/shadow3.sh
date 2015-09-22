#!/bin/bash
codes_download pypi-shadow3
codes_dependencies pykern
pip install -r requirements.txt
python setup.py install
