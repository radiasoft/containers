### Docker and Vagrant Containers for Scientific Codes

RadiaSoft provides the following Vagrant (VirtualBox) and Docker
containers to support scientific computing:

* [radiasoft/python2](https://github.com/radiasoft/containers/tree/master/radiasoft/python2)
  is a basic Python2 pyenv/virtualenv with matplotlib and numpy

* [radiasoft/beamsim](https://github.com/radiasoft/containers/tree/master/radiasoft/beamsim)
  is a physics container for particle accelerator and free electron laser (FEL) simulations.

* [radiasoft/sirepo](https://github.com/radiasoft/containers/tree/master/radiasoft/sirepo)
  is an application framework to simplify the execution of scientific codes.

### Vagrant Invocation

Code is installed within the
[pyenv](https://github.com/yyuu/pyenv) and
[virtualenv](https://virtualenv.pypa.io) except in certain cases (e.g. elegant).
When you ssh into the VirtualBox via vagrant, you will see:

```bash
$ vagrant ssh
Last login: Fri Sep 25 22:29:36 2015 from 10.0.2.2
pyenv-virtualenv: activate py2
[py2;@v ~]$
```
At this point, you are executing in the `py2 virtualenv`, which allows you to execute
`python` or, say, `synergia`:

```bash
$ synergia
usage: /home/vagrant/.pyenv/versions/py2/bin/synergia [synergia_arguments] <synergia_script> [script_arguments]
synergia_arguments:
         -i         : enter interactive Python mode
         --ipython  : enter IPython interactive mode (if available)
         --help     : this message
```

Sometimes you will see the following two lines when logging in:

```bash
Updating: /home/vagrant/src/biviosoftware/home-env
Sourcing: ~/.bashrc
```
These updates to your dot-files happen regularly and automatically
to keep the dot files up to date. See
[biviosoftware/home-env](https://github.com/biviosoftware/home-env)
for more details including how to extend `vagrant`'s dot files.

### Docker Invocation

Docker containers are configured to run the codes as user `vagrant` (UID=1000).

TODO: finish implementing docker-run to run as user `vagrant` with UID/GID from
host UID/GID.

#### Installing Vagrant on Windows


You need to download and install the following (in order):

* [VcXsrv](https://sourceforge.net/projects/vcxsrv/)
  [download installer](http://downloads.sourceforge.net/vcxsrv/vcxsrv/1.17.0.0/vcxsrv-64.1.17.0.0.installer.exe)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
  [download installer](http://download.virtualbox.org/virtualbox/4.3.28/VirtualBox-4.3.28-100309-Win.exe)
* [SSHWindows](http://www.mls-software.com/opensshd.html)
  [download installer](http://www.mls-software.com/files/setupssh-6.8p1-1.exe)
* [Vagrant](https://www.vagrantup.com/downloads.html)
  [download installer](https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2.msi)

You'll need to reboot and start vcxsrv.

```cmd
mkdir vagrant
cd vagrant
```

Then create a file in `vagrant` folder:

```ruby
Vagrant.configure(2) do |config|
  config.vm.box = "radiasoft/beamsim"
  config.vm.hostname = "rsdev"
  config.ssh.forward_x11 = true
  config.vm.synced_folder ".", "/vagrant", disabled: true
end
```

Then do this to download the virtual machine (VM) image (radiasoft/beamsim) from the
Vagrant repository:

```cmd
vagrant up
```

The machine

You'll need to update the "guest additions" for VirtualBox. Get the version
from VirtualBox. You can do this by starting the GUI and looking under the
"About" menu, or you might be able to run `VBoxManage` from the command prompt:

```cmd
VBoxManage --version
```

Once you have the VirtualBox version, you can boot the machine and install
the "Guest Additions" to match your machine's version to the VM's version.
In this example, the version is `4.3.28`:

```bash
vagrant ssh
sudo su -
# REPLACE WITH YOUR VERSION:
v=4.3.28
curl -L -O http://download.virtualbox.org/virtualbox/$v/VBoxGuestAdditions_$v.iso
mount -t iso9660 -o loop VBoxGuestAdditions_$v.iso /mnt
sh /mnt/VBoxLinuxAdditions.run < /dev/null
umount /mnt
rm -f VBoxGuestAdditions_$v.iso
exit
exit
```

Once the install completes, edit the `Vagrantfile` again, removing this line:

```ruby
config.vm.synced_folder ".", "/vagrant", disabled: true
```

At Windows command prompt:

```cmd
vagrant reload
```

After your VM boots, login to your VM as follows:

```cmd
set DISPLAY=localhost:0
vagrant ssh
```

This will "tunnel" X11 so you can display plots and such in Windows from your VM.

You can also add `DISPLAY=localhost:0` to your user environment in the Control Panel
so that you don't have to type the `set` command each time.

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

### Build

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
