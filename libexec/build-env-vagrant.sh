#!/bin/bash
#
# Vagrant functions and variables for build
#

build_container_net=10.10.10

build_clean_dir() {
    vagrant destroy -f &> /dev/null
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
        # Must be different than install-user.sh (so can run two VMs simultaneously)
        # Shouldn't collide with existing uses (1-60) either. Only important for
        # the build if there is a git server
        local -i i=$(perl -e 'print(int(rand(50)) + 60)')
        local ip=
        local x=
        while (( $i < 255 )); do
            x=$build_container_net.$i
            if ! ( echo > /dev/tcp/$x/22 ) >& /dev/null; then
                ip=$x
                break
            fi
            i+=1
        done
        if [[ ! $ip ]]; then
            echo "Unable to find a free IP address on $build_container_net" 1>&2
            exit 1
        fi
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
        | vagrant ssh -- -T "sudo bash -c 'mkdir $build_conf; cd $build_conf; cpio -i'"
    # Don't use bivio_vagrant_ssh, because we don't want to build
    # guest additions on the build machine. It's irrelevant, because
    # aren't sharing files between the two machines.
    vagrant ssh -- -T "sudo build_env='$build_env' bash '$build_script'" < /dev/null
    vagrant halt
    vagrant package --output package.box
    vagrant box add "$build_box" package.box
    # Need to destroy VM because directory is emphemeral
    vagrant destroy -f
    rm -rf Vagrantfile .vagrant
    echo 'See README.md to upload'
}
