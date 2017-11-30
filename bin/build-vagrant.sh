#!/bin/bash
#
# See ./build for usage
#
build_image_add='vagrant box add'

build_clean_container() {
    set +e
    cd "$build_dir"
    vagrant destroy -f
    rm -rf Vagrantfile .vagrant
}

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
    if ! vagrant ssh -- -T "sudo bash '$build_run'" < /dev/null; then
        build_err 'Build failed'
    fi
    vagrant halt
    out=$build_start_dir/${build_image_name//\//-}-$build_version.box
    vagrant package --output "$out"
    vagrant box add "$build_image_name" "$out"
    build_vagrant_version "$build_image_name" "$build_version"
    local uri=$build_vagrant_uri/$(basename "$out")
    cat <<EOF
You need to copy the box:

    $out

to:

    $uri

Then, go to:

    $build_vagrant_cloud_uri/new

Enter the version:

    $build_version

and a description which includes the base image:

    $build_image_base

and source:

    https://github.com/$build_vagrant_org/containers/tree/master/$build_image_name

Click "Create version".

Click "Create new provider". Select the provider:

    virtualbox

Select "External URL" and fill "URL" with:

    $uri

Click "Create provider".

Click "Release" to the right of "v$build_version" string:

    $build_image_uri/edit

Click "Release version"

Test on another machine:

    vagrant init $build_image_name
    vagrant up
EOF
}

build_image_prep() {
    local -a x=( ${build_image_name//\// } )
    build_vagrant_org=${x[0]}
    build_vagrant_repo=${x[1]}
    build_vagrant_cloud_uri=https://app.vagrantup.com/$build_vagrant_org/boxes/$build_vagrant_repo/versions
    build_image_uri=$build_vagrant_cloud_uri/$build_version
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
        build_yum remove "${x[@]}" || true
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

build_vagrant_version() {
    local image=$1
    local version=$2
    local dir=$HOME/.vagrant.d/boxes/${image/\//-VAGRANTSLASH-}
    mv "$dir/0" "$dir/$version"
    local meta=$dir/metadata_url
    if [[ ! -f $meta ]]; then
        echo -n "https://app.vagrantup.com/$image" > "$meta"
    fi
}
