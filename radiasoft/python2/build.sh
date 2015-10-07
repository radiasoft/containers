#!/bin/bash
if [[ $build_is_vagrant ]]; then
    build_image_base=hansode/fedora-21-server-x86_64
else
    build_image_base=fedora:21
fi

run_as_exec_user() {
    if [[ $build_is_vagrant ]]; then
        sudo rpm --import https://yum.dockerproject.org/gpg
        sudo cp docker.repo /etc/yum.repos.d/docker.repo
        build_yum install docker-engine
        sudo usermod -a -G docker vagrant
        sudo systemctl enable docker.service
    fi
    cd
    # This line stops a warning from the pyenv installer
    bivio_path_insert ~/.pyenv/bin 1
    . ~/.bashrc
    bivio_pyenv_2
    . ~/.bashrc
    pip install --upgrade pip
    # some setup.py's fail if numpy not installed before calling python setup.py
    # Last known working version is 1.9.3. pypi-shadow3 setup fails with:
    #
    #   File "/home/vagrant/.pyenv/versions/2.7.10/lib/python2.7/site-packages/numpy/distutils/command/build_clib.py", line 52, in finalize_options
    #     self.set_undefined_options('build', ('parallel', 'parallel'))
    #   File "/home/vagrant/.pyenv/versions/2.7.10/lib/python2.7/distutils/cmd.py", line 303, in set_undefined_options
    #     getattr(src_cmd_obj, src_option))
    #   File "/home/vagrant/.pyenv/versions/2.7.10/lib/python2.7/distutils/cmd.py", line 105, in __getattr__
    #     raise AttributeError, attr
    #   AttributeError: parallel
    # Seems that set_undefined_options looks up the command by name ("build") and
    # doesn't get numpy.distutils.command.build, which has "parallel".
    # Tried adding numpy.distutils.core.setup to pksetup.setup, and that
    # resulted in:
    #   AttributeError: py_modules_dict
    # No time to debug now.
    pip install numpy==1.9.3
    pip install matplotlib
}
