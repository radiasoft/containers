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
    local private_net=
    if [[ $BIVIO_GIT_SERVER ]]; then
        ip=$(perl $build_libexec_dir/find-available-ip.pl "$build_container_net")
        assert_subshell
        private_net="config.vm.network \"private_network\", ip: \"$ip\""
    fi

    cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
  config.vm.box = "$build_base_vagrant"
  $private_net
  # Guest additions are out of date. Boot without shared folder,
  # because otherwise will get an error and slow down build
  config.vm.synced_folder ".", "/vagrant", disabled: true
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
    # Need to destroy VM because directory is emphemeral
    vagrant destroy -f
    rm -rf Vagrantfile .vagrant
    echo 'See README.md to upload'
}
