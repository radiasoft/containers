#!/bin/bash
codes_dependencies pykern common
codes_download robnagler/shadow3
codes_patch_requirements_txt
python setup.py install
