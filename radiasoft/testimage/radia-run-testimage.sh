#!/bin/bash
. ~/.bashrc
set -e
env
python -c 'import json; assert float(json.load(open("/RSMANIFEST.json"))["version"]) > 20170101.'
cat /RSMANIFEST.json
