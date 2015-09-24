#!/bin/bash
codes_dependencies common
codes_download https://depot.radiasoft.org/foss/SDDSToolKit-3.3.1-1.fedora.21.x86_64.rpm
codes_download https://depot.radiasoft.org/foss/SDDSPython-3.2-1.fedora.21.x86_64.rpm
install -m 0644 $(rpm -ql SDDSPython | grep ^/usr/lib/python2.7/site-packages) "$codes_lib_dir"
