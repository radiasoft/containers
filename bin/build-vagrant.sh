#!/bin/bash
#
# See ./build for usage
#

build_image() {
    cat > Vagrantfile <<EOF
Vagrant.configure(2) do |config|
  config.vm.box = "$build_image_base"
  # Guest additions are out of date. Boot without shared folder,
  # because otherwise will get an error and slow down build
  config.vm.synced_folder ".", "/vagrant", disabled: true
  # https://github.com/mitchellh/vagrant/issues/5186
  # Can't insert a private key, because would have to be packaged with
  # the box. If you rebuild the original box, it will mess with the
  # key.
  config.ssh.insert_key = false
  # Avoids xauthority file showing up
  config.ssh.forward_x11 = false
  # Need enough memory and CPU to compile synergia
  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 2
  end
end
EOF
    vagrant up
    # Do not use bivio_vagrant_ssh, because something may go wrong with boot
    # We don't have tar with hansode/fedora-21-server-x86_64
    (cd "$build_dir"; find . -name .vagrant -prune -o -type f -print | cpio -o) \
        | vagrant ssh -- -T "sudo bash -c 'rm -rf $build_guest_conf; mkdir -p $build_guest_conf; cd $build_guest_conf; cpio -iud'"
    # Don't use bivio_vagrant_ssh, because we don't want to build
    # guest additions on the build machine. It's irrelevant, because
    # aren't sharing files between the two machines.
    vagrant ssh -- -T "sudo bash '$build_run'" < /dev/null
    vagrant halt
    out=$build_start_dir/${build_image_name//\//-}-$build_version.box
    vagrant package --output "$out"
    vagrant box add "$build_image_name" "$out"
    local uri=$build_vagrant_uri/$(basename "$out")
    local -a x=( ${build_image_name//\// } )
    cat <<EOF
You need to copy the box:
    $out
to:
    $uri

Then, go to:
    https://atlas.hashicorp.com/${x[0]}/boxes/${x[1]}/versions/new

Enter the version:
    $build_version

and a description which includes the base image:
    $build_image_base
and source:
    https://github.com/radiasoft/containers/tree/master/$build_image_name

Click "Create version".

Click "Create new provider". Select the provider:
    virtualbox

Select "URL" and fill "HTTP URL"
    $uri

Click "Create provider".

Click "Edit" to the left of "v$build_version" button:
    https://atlas.hashicorp.com/${x[0]}/boxes/${x[1]}/versions/$build_version/edit

Click "Release version"

Test on another machine:
    vagrant init $build_image_name
    vagrant up
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
}

build_image_clean() {
    if ! build_image_exists "$build_image_name"; then
        return 0
    fi
    vagrant box remove "$build_image_name"
}

build_image_exists() {
    local img=$1
    if vagrant box list | grep -s -q "^$img "; then
        return 0
    fi
    return 1
}

build_init_type() {
    build_is_vagrant=1
    build_type=vagrant
}

build_root_setup() {
    local x=/etc/NetworkManager/dispatcher.d/fix-slow-dns
    if [[ ! -r $x ]]; then
        cat >> "$x" <<'EOF'
#!/bin/bash
# Fix slow DNS by updating resolve.conf
# http://fedoraforum.org/forum/showthread.php?t=238593
# https://github.com/mitchellh/vagrant/issues/1172#issuecomment-42263664
# https://github.com/chef/bento/blob/master/scripts/fedora/fix-slow-dns.sh
echo 'options single-request-reopen' >> /etc/resolv.conf
EOF
        chmod 550 "$x"
        systemctl restart NetworkManager
    fi
    x=/swap
    if [[ ! -e $x ]]; then
        dd if=/dev/zero of="$x" bs=1M count=1024
        mkswap "$x"
        chmod 600 "$x"
        swapon "$x"
        echo "$x none swap sw 0 0" >> /etc/fstab
    fi
    perl -pi -e 's{^(X11Forwarding) no}{$1 yes}' /etc/ssh/sshd_config
    systemctl restart sshd.service
    # Containers are protected by their hosts
    (
        systemctl stop firewalld.service
        systemctl disable firewalld.service
    ) >& /dev/null || true
    # Remove the VirtualBox guest additions here so that the
    # initial boot on the client machines goes faster, since
    # these are surely the wrong version.
    x=( $(rpm -qa | grep VirtualBox || true) )
    if [[ $x ]]; then
        # Remove the virtual box RPMs
        build_yum "${x[@]}" || true
    fi
    x=~vagrant/.ssh/authorized_keys
    if ! grep -s -q insecure "$x"; then
        local d="$(dirname "$x")"
        if [[ ! -d $d ]]; then
            mkdir "$d"
        fi
        build_curl https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub >> "$x"
        chmod -R og-rwx "$d"
    fi
}
