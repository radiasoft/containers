#!/bin/bash
#
# See ../lib.sh for usage
#

. ../lib.sh

build_bashrc() {
    local bashrc=$1/.bashrc
    if [[ $(readlink -f $bashrc) =~ /home-env/ ]]; then
        return 0
    fi
    local user=$(basename "$1")
    local x=$build_guest_conf/home-env-install.sh
    if [[ ! -r $x ]]; then
        curl -s -S -L https://raw.githubusercontent.com/biviosoftware/home-env/master/install.sh > "$x"
    fi
    no_perl=1 bash "$x"
}

build_image() {
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
    (cd "$build_host_conf"; find . -maxdepth 1 -type f | cpio -o) \
        | vagrant ssh -- -T "sudo bash -c 'rm -rf $build_guest_conf; mkdir -p $build_guest_conf; cd $build_guest_conf; cpio -iu'"
    # Don't use bivio_vagrant_ssh, because we don't want to build
    # guest additions on the build machine. It's irrelevant, because
    # aren't sharing files between the two machines.
    vagrant ssh -- -T "sudo bash '$build_run'" < /dev/null
    vagrant halt
    out=${build_image_name//\//-}.box
    vagrant package --output "$out"
    vagrant box add "$build_image_name" "$out"
    cat <<EOF
Built: $build_image_name:$build_version
To push to the vagrant hub:
    vagrant push '$tag'
    vagrant push '$latest'
EOF
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
    cd /
    rm -rf "$build_dir"
    echo 'See README.md to upload'
}

build_image_clean() {
    if ! build_image_exists "$build_image_name"; then
        return 0
    fi
    vagrant box remove "$build_image_name"
}

build_image_exists() {
    local img=$1
    if [[ vagrant box list | grep -s -q "^$img " ]]; then
        return 0
    fi
    return 1
}

build_run() {
    cd "$(dirname "$0")"
    build_init
    if [[ $UID == 0 ]]; then
        build_fedora_patch
        # Need these to build home environment
        yum install -y git tar
        build_bashrc ~
        run_as_root
        # Run again, because of update or yum install may reinstall pkgs
        build_fedora_patch
        chown -R "$build_exec_user:$build_exec_user" .
        su "$build_exec_user" "$0"
        build_fedora_clean
    else
        build_bashrc ~
        . ~/.bashrc
        run_as_exec_user
    fi
}

build_main "$@"
