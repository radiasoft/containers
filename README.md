### fedora-container

Fedora 21 on Docker or Vagrant with Python development environment including
the following codes:

* Elegant
* SRW
* Shadow3
* Synergia
* WARP

### Install on Windows

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

```bash
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

Then do this to download the VM:

```
vagrant up
vagrant ssh
```

Inside the VM, you'll need to:

```bash
sudo su -
curl -L -O http://download.virtualbox.org/virtualbox/4.3.28/VBoxGuestAdditions_4.3.28.iso
mount -t iso9660 -o loop VBoxGuestAdditions_4.3.28.iso /mnt
sh /mnt/VBoxLinuxAdditions.run < /dev/null
umount /mnt
rm -f VBoxGuestAdditions_4.3.28.iso
exit
exit
```

Edit the `Vagrantfile` again, removing this line:

```
config.vm.synced_folder ".", "/vagrant", disabled: true
```

At Windows command prompt:

```
vagrant reload
```

The VM is running. You can then do this (in the vagrant directory) to run vagrant:

```
set DISPLAY=localhost:0
vagrant ssh
```

You will need to add `DISPLAY=localhost:0` to your environment so that you don't
have to type the `set` command each time.

### Installing accelerator codes manually (in RadiaSoft containers):

```bash
cd ~/src/radiasoft
git clone https://github.com/radiasoft/containers
cd containers/radiasoft/beamsim
bash codes.sh <code1> <code2> ...
```

If you do not pass a list of codes to `codes.sh`,
it will try to install them all.  The list of available codes
are: elegant genesis shadow3 srw synergia warp.
