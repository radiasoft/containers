#!/bin/bash
. ~/.bashrc
set -e
env
python -c 'import json; assert float(json.load(open("/rsmanifest.json"))["version"]) > 20170101.'
cat /rsmanifest.json
