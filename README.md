### Docker and Vagrant Containers for Scientific Codes

RadiaSoft provides the following Vagrant (VirtualBox) and Docker
containers to support scientific computing.

#### Installation

The best way to install is to use our
[automated downloader](https://github.com/radiasoft/download).

#### Image List

The follow container images are available:

* [radiasoft/beamsim](https://github.com/radiasoft/containers/tree/master/radiasoft/beamsim)
  is a physics container for particle accelerator and free electron laser (FEL) simulations.
* [radiasoft/python2](https://github.com/radiasoft/containers/tree/master/radiasoft/python2)
  is a basic Python2 (currently 2.7.10) pyenv with matplotlib and numpy.
* [radiasoft/radtrack](https://github.com/radiasoft/containers/tree/master/radiasoft/radtrack)
  is an desktop to simplify the execution of accelerator codes
* [radiasoft/sirepo](https://github.com/radiasoft/containers/tree/master/radiasoft/sirepo)
  is an web application to simplify the execution of scientific codes.

### Installing RadiaSoft development VM on Unix-like systems

To create a development VM on your Mac or Linux (Cygwin untested at this time), you
can do the following:

```sh
curl -s -S -L https://raw.githubusercontent.com/radiasoft/containers/master/bin/vagrant-up-dev | bash
```

This will create the VM, updated the guest additions to match the host sytem,
copy in certain dot files (.docker, .gitconfig, .hgrc, .netrc, and/or .pypirc)
from the host user's (your) home directory to the guest user's home. It will
also clone and install [pykern](https://github.com/radiasoft/pykern)
and [sirepo](https://github.com/radiasoft/sirepo).

The following environment variables can be set in advance:

* host -- hostname for the virtual machine [default: rs]
* ip -- local private network address [default: 10.10.10.10]
* box -- vagrant box name [default: radiasoft/beamsim]

### Installing accelerator codes manually (in RadiaSoft containers):

```bash
cd ~/src/radiasoft
git clone https://github.com/radiasoft/containers
cd containers/radiasoft/beamsim
bash codes.sh <code1> <code2> ...
pyenv rehash
```

If you do not pass a list of codes to `codes.sh`,
it will try to install them all.  The list of available codes
are: elegant genesis shadow3 srw synergia warp.

If you are developing PyKern, after the install, you'll need to:

```bash
cd ~/src/radiasoft/pykern
python setup.py develop
```

#### Build

To build docker or vagrant images, you have to:

```bash
cd containers
bin/build docker radiasoft/python2
```

The command should finish with instructions how to get the images
into the vagrant or docker hub.

Once

#### Querying Docker Registry

The `docker` command doesn't have many features to query the docker registry.
The web GUI is even worse. You can't know from the interface which image is
associate with which tag.

To query all the tags in the registry, you use curl, e.g. for `radiasoft/beasim`:

```bash
curl https://registry.hub.docker.com/v1/repositories/radiasoft/beamsim/tags
```

## Jupyter server at https://jupyter.radiasoft.org -- usage tips

### Importing the Warp code in an IPython Notebook

Simply trying 'import warp' or 'from warp import *' will generate errors.
Instead, use the following:
'''import sys
del sys.argv[1:]
from warp import *
'''

### European XFEL: the WaveProperGator (WPG) notebooks for running SRW

1) Point your browser to the following address:
https://jupyter.radiasoft.org 

2) Login with your GitHub credentials.

3) Click green button, "My Server"

4) Near the upper right, click "New" and then select "Terminal"

5) In the new terminal window, type the following command:
jupyter$ git clone https://github.com/samoylv/WPG.git ./WPG

6) Return to browser tab where you originally logged in to the server.
Or alternatively, click the 'Jupyter' logo near the upper left.

7) Browse to a notebook, by doing (for example) the following:
'''Click "WPG"
Click "samples"
Click "Tutorials"
Click "Tutorial_case_1.ipynb"
'''
