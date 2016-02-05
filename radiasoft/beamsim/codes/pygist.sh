#!/bin/bash
pip install numpy
codes_download https://bitbucket.org/dpgrote/pygist.git
python setup.py config
python setup.py install
