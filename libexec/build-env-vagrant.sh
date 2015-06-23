#!/bin/bash
#
# Vagrant functions and variables for build
#

if ! vagrant box list | grep -s -q "^$build_base_vagrant "; then
    build_err "$build_base_vagrant: not in vagrant box list"
fi

build_container_net=10.10.10

build_clean_dir() {
    vagrant destroy -f &> /dev/null || true
}

build_clean_box() {
    if vagrant box list | grep -s -q "$build_box"; then
        # If there is a VM running or dependent on it, will get an error
        vagrant box remove "$build_box"
    fi
}

build_run() {
    cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
  config.vm.box = "$build_base_vagrant"
  # Guest additions are out of date. Boot without shared folder,
  # because otherwise will get an error and slow down build
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # https://github.com/mitchellh/vagrant/issues/5186
  # Can't insert a private key, because would have to be packaged with
  # the box. If you rebuild the original box, it will mess with the
  # key.
  config.ssh.insert_key = false
end
EOF
    vagrant up
    # Do not use bivio_vagrant_ssh, because something may go wrong with boot
    # We don't have tar with hansode/fedora-21-server-x86_64
    find . -maxdepth 1 -type f | cpio -o \
        | vagrant ssh -- -T "sudo bash -c 'rm -rf $build_conf; mkdir -p $build_conf; cd $build_conf; cpio -iu'"
    # Don't use bivio_vagrant_ssh, because we don't want to build
    # guest additions on the build machine. It's irrelevant, because
    # aren't sharing files between the two machines.
    vagrant ssh -- -T "sudo build_env='$build_env' bash '$build_script'" < /dev/null
    vagrant halt
    out=${build_box//\//-}.box
    vagrant package --output "$out"
    vagrant box add "$build_box" "$out"
    # This doesn't work:
    #
    # vagrant box add --box-version "$(date +%Y%m%d.%H%M%S)" radiasoft/fedora file://$PWD/package.box
    #
    # Run vagrant up without adding the box manually using vagrant box add
    #
    # VERSION OF BOX; Store in box, too.
    # https://github.com/hollodotme/Helpers/blob/master/Tutorials/vagrant/self-hosted-vagrant-boxes-with-versioning.md#4-using-a-box-catalog-for-versioning
    #
    # openssl sha1 ~/VagrantBoxes/devops_0.1.0.box
    # {
    #     "name": "devops",
    #     "description": "This box contains Ubuntu 14.04.1 LTS 64-bit.",
    #     "versions": [{
    #         "version": "0.1.0",
    #         "providers": [{
    #                 "name": "virtualbox",
    #                 "url": "file://~/VagrantBoxes/devops_0.1.0.box",
    #                 "checksum_type": "sha1",
    #                 "checksum": "d3597dccfdc6953d0a6eff4a9e1903f44f72ab94"
    #         }]
    #     }]
    # }
    #
    # config.vm.box_url = "file://~/VagrantBoxes/devops.json"
    #
    # Need to destroy VM because directory is emphemeral
    vagrant destroy -f
    rm -rf Vagrantfile .vagrant
    echo 'See README.md to upload'
}
