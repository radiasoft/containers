### Basic Docker Usage

A short tutorial on Docker. If you don't know what Docker is,
[read this first](FIXME).

This tutorial uses Docker from the command line so you
should be familiar with the Linux command line. In general, you won't
be using Docker as a full-blown development environment. You can, of
course, but it's better to use Linux directly, and use Docker for
testing and deployment. Rather, it's more like running `make`
from the shell than from your IDE. The
[Docker Hub](https://hub.docker.com) is quite primitive unlike
say, [GitHub](https://github.com) so that's another reason
to be familiar with the Docker command line.

At RadiaSoft, we don't usually invoke Docker directly. It's a
great tool for isolating execution environments, but it's
a bit like booting a machine every time you want to run a
few commands. It's not super inconvient, just enough so
that we wrap it up in
[some simple scripts](https://github.com/radiasoft/containers)
so you don't have to rememer to do
all the things we'll be talking about below.

There are of course more advanced automation tools for Docker. They
may be more suitable for you, but at RadiaSoft, we deal with lots of
custom build systems for physics codes and supercomputers so there's
no COTS automation for this, unfortunately. Also, it's useful to know
what's going on under the covers, which this tutorial gets into in
quite some detail.

Before getting started, you'll need to
[install Docker](FIXME).
We also recommend you run Docker as an
[ordinary user](FIXME)
since it's easy to confuse executing commands on the host as root and
inside a docker container, which boots into root. Installation is not
part of this tutorial, since that's system dependent.  The cool part
is that once you've installed it, you now have the ability to run
whatever flavor of Linux -- GNU, technically -- that suits your fancy
and application requirements.

For simplicity and speed of download, we'll use the
[Busybox](https://hub.docker.com/_/busybox/)
is a very small image
image from the [Docker Hub](https://hub.docker.com),
which is a very tiny (less than one megabyte) distro that is
used by many embedded devices such as WiFi routers and set-top
boxes. It's got `bash` and a simple `httpd`, which will let us
demonstrate all the features you probably need.

With all those caveats out of the way, let's play with Docker!

#### Basic Execution

`docker run` downloads the image, unpacks it, boots the container,
and runs a shell command:

```bash
$ docker run busybox echo Hello, World!
Unable to find image 'busybox:latest' locally
latest: Pulling from library/busybox
library/busybox:latest: The image you are pulling has been verified. Important: image verification is a tech preview feature and should not be relied on to provide security.
Digest: sha256:3ebe07818fc2a8001cbb672b878ab0b81f047066093bb9c3f05600514710b921
Status: Downloaded newer image for busybox:latest
Hello, World!
```

Next time you run, it's faster, because all Docker daemon has to
do is boot the container and run the command:

```bash
$ time docker run busybox echo Hello, World!
Hello, World!

real	0m0.664s
user	0m0.031s
sys	    0m0.034s
```

You can run an interactive shell by passing the flags `-t` to allocate a pseudo-tty
and `-i` to run interactively (keep stdin open):


```bash
$ docker run -i -t busybox sh
/ # echo hello
hello
/ # ls
bin   dev   etc   home  proc  root  sys   tmp   usr   var
/ # ls /etc
group        hostname     hosts        mtab         passwd       resolv.conf  shadow
```

Running commands in a Docker container is much like ssh'ing into
a virtual machine. It's also similar to running an interactive shell
on the host machine. However, there are subtle differences, for example,
control-P is the escape character in interactive mode, and you can't
change it. If you are running the container in an Emacs shell window,
it can be annoying to type control-P twice to go up one line.

#### Root User

The `#` bash prompt indicates you are running as root
inside the container. That has some important consequences,
which we'll discuss later. For now, it's practical, since you
almost always have to install files only accessible as root,
for example:

```bash
/ # touch /etc/my-app-config
/ # ls /etc
group          hosts          my-app-config  resolv.conf
hostname       mtab           passwd         shadow
```

This just added a file to `/etc` as root, which is something
many apps require. In a freshly booted container, you are
going to have to configure it to do something other than
run `sh`. So put on your sysadmin hat, and we'll configure
a tiny application.

Quick aside. Busybox is truly a minimal distro. When was the
last time you administered a system which has a `/etc`
with only eight files? Neat.

#### Images and Containers

Docker has two distinct objects: *images* and *containers*.
An image is just a tarball that Docker unpacks and
instantiates as a container (process).  Images are static
entities. Containers, OTOH, are either running (`Up`)
or stopped (`Exited`). You use `docker ps` to see what
the state of *all* containers on the host are:

```bash
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS                      PORTS               NAMES
60e4e25ef570        busybox             "sh"                     38 minutes ago      Up 38 minutes                                   serene_payne
fc213ce6cd24        busybox             "echo Hello, World!"     39 minutes ago      Exited (0) 39 minutes ago                       cranky_noyce
32b3f2e47b87        busybox             "echo Hello, World!"     40 minutes ago      Exited (0) 40 minutes ago                       goofy_torvalds
```
Here you see that we ran Docker three times: two echo commands
and one interactive sh that's still running. You can see that
Docker doesn't clean up stopped containers. You can restart them,
but unlike images, you can't change the command that will be run.
Let's restart `goofy_torvalds`:

```bash
$ docker start -a -i cranky_noyce
Hello, World!
```

Not very interesting, because `echo` isn't a useful
application. Alternatively, you might be running some physics
simulation, which failed due to a configuration issue, and the `start`
command might be useful to restart it. That's not the typical
use, but it is definitely useful for debugging.

One thing to note is that the `docker` command is a front-end
that sends messages to the docker daemon. Therefore, `ps -a`
shows all runnning and stopped containers on the machine, and
you can't know which (host) user started which container. Just
something to keep in mind when running Docker on a shared computer.

You can also list all the images on the host computer with
the `images` command:

```bash
$ docker images
[2.7.10;@v docker]$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
busybox             latest              0064fda8c45d        40 minutes ago      1.113
M
```

#### Containers are not Virtual Machines

A container is not a virtual machine (VM), because it does not emulate
any hardware. The container processes are running on the host computer
as any other process, sharing resources between all the other processes
on the host computer. In a VM, the resources are allocated by the hypervisor,
which manages the sharing through its own algorithms, outside the control
of each VM on the host computer.

Here's a way to convince yourself that a docker container is on
the same computer. Start a `sleep` with a unique number of seconds
in your Docker container, then run `ps` to see it is there:

```bash
/ # sleep 123 &
/ # ps a
PID   USER     TIME   COMMAND
    1 root       0:00 sh
   42 root       0:00 sleep 123
   43 root       0:00 ps a
```

In a different window on your host computer, run a `ps a | grep sleep`,
and you'll see the sleep process:

```bash
$ ps a | grep sleep
32327 pts/3    S      0:00 sleep 123
32350 pts/4    S+     0:00 grep sleep
```

A container is therefore just a process on your host computer, which
has restricted access to the host computer's resources.

#### Containers are Ephemeral

One strange thing about Docker containers is that they
are ephemeral. As shown above, each time you run an
image it creates a new container. That container is
an exact copy of the image. (Actually, it is the image,
but we'll get to that in a bit.)

Starting from exactly what's in the image is very
useful for testing. However, it can be confusing at times
so that's why it's emphasized here. Here's a demonstration
of the effect:

```bash
$ docker run -i -t busybox sh -c 'ls; touch aaa; ls'
bin   dev   etc   home  proc  root  sys   tmp   usr   var
aaa   bin   dev   etc   home  proc  root  sys   tmp   usr   var
$ docker run -i -t busybox sh -c 'ls; touch aaa; ls'
bin   dev   etc   home  proc  root  sys   tmp   usr   var
aaa   bin   dev   etc   home  proc  root  sys   tmp   usr   var
$
```

The first `ls` shows `/aaa` does not exist. After the `touch`
it does in the first container. In the second container, it
has to be recreated again.

#### Building Images

Images can be created with the `build` command.
You describe what you want in the image in the `Dockerfile`.
At a minimum, you need to specify the base image which
you are going to extend. We'll also specify the maintainer
of the image:

```bash
FROM busybox
MAINTAINER RadiaSoft <docker@radiasoft.net>
```

After creating this `Dockerfile`, you run `build`:

```bash
$ time docker build .
Sending build context to Docker daemon 17.41 kB
Step 0 : FROM busybox
 ---> 0064fda8c45d
Step 1 : MAINTAINER RadiaSoft <docker@radiasoft.net>
 ---> Using cache
 ---> cda15ffd2f27
Successfully built cda15ffd2f27

real	0m0.107s
user	0m0.030s
sys     0m0.033s
```

This is very fast, because Docker doesn't copy the base image.
Instead it uses
[advanced multi layered unification filesystem (aufs](https://en.wikipedia.org/wiki/Aufs)
to layer the new image on the old image. This is one of the very cool
things about Docker, because you can distribute the (large) base
system containing all the common libraries and tools infrequently with
the application image being very small and fast to distribute.

We can see our new image was created with the `images` command:

```bash
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
<none>              <none>              cda15ffd2f27        8 minutes ago       1.113 MB
busybox             latest              0064fda8c45d        42 hours ago        1.113 MB
```

You see the busybox base image along with our new image (`cda15ffd2f27`).
As you can see busybox has a *repository* name of `busybox` and a *tag* of `latest`
(the default). Our new box is not identified as such, but we can run it
by its image identifier `cda15ffd2f27`:

```bash
$ docker run cda15ffd2f27 echo hello
hello
```

You'll want to give your images constants names, which you can do with
the `tag` command:

```bash
$ docker tag cda15ffd2f27 my-app
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
my-app              latest              cda15ffd2f27        13 minutes ago      1.113 MB
busybox             latest              0064fda8c45d        42 hours ago        1.113 MB
```

Typically, you tag your image when you build it as follows:

```bash
$ docker build -t my-app .
docker build -t my-app .
Sending build context to Docker daemon 19.97 kB
Step 0 : FROM busybox
 ---> 0064fda8c45d
Step 1 : MAINTAINER Rob Nagler
 ---> Using cache
 ---> cda15ffd2f27
Successfully built cda15ffd2f27
```

Now, take a look at the list of images:

```bash
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
my-app              latest              cda15ffd2f27        15 minutes ago      1.113 MB
busybox             latest              0064fda8c45d        42 hours ago        1.113 MB
```

Wait, what happened? Nothing. The image was rebuilt, but it had exactly the
same contents as the previous build so docker didn't do anything. This is a
bit strange, but makes a lot of sense in that docker builds are idempotent,
which makes the process of creating and running a docker image reproducible.
Docker uses the hash of the image for its ID, which is how it verifies that
nothing has changed.

#### Simple Application

A Dockerfile typically has more information than just the base box and
maintainer. You add instructions to provision the image.  You provide
configuration files with the `ADD` command, and you install them with
the `RUN` command. Here's a more complex Dockerfile:

```bash
FROM busybox
MAINTAINER Rob Nagler
ADD . /cfg
RUN chmod +x /cfg/hello-world.sh
CMD /cfg/hello-world.sh
```

The `ADD` instruction tells Docker to copy the contents of the build
directory (`.`) on the host to the build container (guest). Note that
`docker build` instantiates the base image (`FROM`) as a
container, which then is modified and persisted all in one step.

The `RUN` command is executed in the build container (under `sh
-c`). There can be multiple `RUN` commands in a Dockerfile, but
it's often simpler (and easier to test) a single provisioning script,
which we'll show how to do below.

The `CMD` instruction is what Docker executes after the image is
instantiated as a container. You can override the `CMD`.

We put these instructions in `Dockefile-my-app` in this repo so
we can execute the build as follows:

```bash
$ docker build -f Dockerfile-my-app -t my-app .
```

There's also a file name `Dockerfile` in the current directory so
we need to specify our uniquely named `Dockerfile-my-app`. We
tag our image `my-app` at build time so we can run our tiny
app as follows:

```bash
$ docker run my-app
Hello, World!
```

We give the image name, and `run` instantiates the image and runs the command
`/cfg/hello-world` contained in the image by default. We can override
the default command, which can be very useful for debugging images.

#### Running a Server

Docker is often used to build servers. There are many features to
support running servers, a few of which, we'll demonstrate here.

Busybox has a built in web server, which can run CGI scripts so we
can show how you would build a simple web application.

In the current directory, there are a number of other files to help
us build the web server. We're into automation so the build and
run process are scripts. Let's go through them one at a time.

##### build-httpd.sh

The build script removes the previous version of the image with
the tag `radiasoft/httpd`. It then builds the image with the
same tag:

```bash
set -e
tag=radiasoft/httpd
name=$(basename "$tag")
docker rmi "$tag" >&/dev/null || true
docker build -f Dockerfile-"$name" -t "$tag" .
```

You'll see `set -e` in all RadiaSoft scripts. We believe
programs should
[fail-fast](https://en.wikipedia.org/wiki/Fail-fast)
before they run amock, possibly doing some real damage.

The `$tag` assignment is followed by an assignment of the
`$name` which is assigned the tag's base name `httpd`. This
is used to identify `Dockerfile-httpd`.

##### Dockerfile-httpd

For tutorial purposes, we'll build the image `radiasoft/httpd`
off of the `my-app` image we created earlier. This shows how
Docker images are layered.

This new Dockerfile uses a new instruction `ENV` to specify environment
variables:

```bash
FROM my-app
MAINTAINER Radiasoft <docker@radiasoft.net>
ENV HTTPD_USER=www-data
ENV HTTPD_ROOT=/www
ADD . /cfg2
RUN sh /cfg2/provision-httpd.sh
CMD httpd -f -h $HTTPD_ROOT -u $HTTPD_USER:$HTTPD_USER -p $HTTPD_PORT
```

We use two environment variables `$HTTPD_USER` and `$HTTPD_ROOT`
to share the configuration between the provisioner and the `CMD`.  Both
the build (provisioning) and execution (run) containers see these
environment variables, which is convenient.

In our new image, he default command is `httpd` with a number of flags.
`-h` sets the root of the tree that the httpd will server, which is
`/www` in this case. `-u` sets the user and group of the httpd process
after it opens the port. We don't want the server to have root access,
of course. We use the unprivileged uses `www-data`, which is built
into Busybox for this purpose.

`-p` sets the port to whatever the value of `$HTTPD_PORT` is at
run time. The mapping of host to container ports happens at run
time so we'll need to pass that to the `run` command.

An important flag is `-f` which says to run `httpd` in foreground instead
of daemon mode (default). Docker containers will exit if the initial
process (by default the `CMD` value) exits. When a daemon runs, it
creates a new
[Linux session](https://www.win.tue.nl/~aeb/linux/lk/lk-10.html#ss10.3)
which means that the Docker daemon can no longer monitor that process
so the container exits. That's not what we want so we run the httpd
in foreground. We'll discuss how to run a docker container in daemon
mode in a bit.

##### provision-httpd.sh

You probably noticed that the `RUN` command now runs a script
called `provision-httpd.sh`. This script does the work of setting
up the files in the image. Here are the non-comment lines of the
script:

```bash
set -e
mkdir -p "$HTTPD_ROOT"/cgi-bin
install -m 400 /cfg2/index.html "$HTTPD_ROOT"/index.html
install -m 500 /cfg2/hello-world.cgi "$HTTPD_ROOT"/cgi-bin/hello-world
chgrp -R "$HTTPD_USER" "$HTTPD_ROOT"
chmod -R g+rX,a-w "$HTTPD_ROOT"
chgrp "$HTTPD_USER" /cfg /cfg/hello-world.sh
chmod g+x /cfg
chmod g+rx /cfg/hello-world.sh
```

The script sets up the `/www/cgi-bin` where the `hello-world.cgi`
[Common Gateway Interface (CGI)](https://en.wikipedia.org/wiki/Common_Gateway_Interface)
application lives. Other files like `index.html` are installed.
We give permission for the `www-data` to read all the files in `/www`,
but `www-data` cannot write anywhere in the tree. At RadiaSoft,
we use the
[Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
when giving permissions.

One of the advantages of Docker is that
it allows you to restrict permissions without causing problems
with reinstalls. Every Docker build starts over at the beginning
so you don't have to worry about read-only directories or files
when installing as a non-root user -- something we recommend,
but don't do in this case to simplify the examples.

#### hello-world.cgi

To make the example more interesting, we have the `hello-world`
CGI program call `hello-world.sh`, which was installed in
the base image (`my-app`). We also have it dump some more
information about the system to help demonstrate how Docker
shares the same kernel as the host computer:

```bash
escape_html() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; '"s/'/\&#39;/g"
}

cat <<EOF
Content-Type: text/html

<html>
<title>Hello</title>
<body>
<h4>$(escape_html "$(/cfg/hello-world.sh)")</h4>
<div style="white-space: pre">
You are $(escape_html "$REMOTE_ADDR").

My uname is $(escape_html "$(uname -a)").
I'm running $(escape_html "$SERVER_SOFTWARE").
</div>
</body></html>
EOF
```

CGI programs write to stdout, which then gets sent to the
browser. They should specify the `Content-Type`, and in
our case, should ensure that all HTML is escaped properly.
We use a simple and restrictive sed script to escape the code,
and embed the escapes in a single call to `cat`.

##### Build the Server

With all our scripts in place, we can now build the
container:

```bash
$ bash build-httpd.sh
Sending build context to Docker daemon 66.56 kB
Step 0 : FROM my-app
 ---> d4f4fbca48a5
 [...snip...]
Removing intermediate container 434854fe663e
Successfully built b4dbda3fd331
```

You'll see
a lot more output than with our simple application.
The `Removing intermediate container` is interesting,
because each Dockerfile instruction actually creates
a new container. This can
[cause confusion)[http://www.markbetz.net/2014/01/31/docker-build-files-the-context-of-the-run-command/],
because each command is a new shell invocation.
That's another good reason to use a single
provisioning script, which executes multiple commands.

##### run-httpd.sh

Now that we have a container built, we can run it. For this
we use a script, too, called `run-httpd.sh`, which
calls `docker run`:

```bash
set -e
tag=radiasoft/httpd
name=$(basename "$tag")
port=8000
docker rm -f "$name" >&/dev/null || true
id=$(docker run -d --name="$name" -p "$port:$port" -e HTTPD_PORT="$port" "$tag")
echo "
Container id: $id

Point your browser to: http://localhost:$port

Stop with: docker stop $name
"
```

Since we want this command to be reentrant, we have it remove
the existing container even if it is running, using `docker rm -f`.
This command will fail if the container does not exist so we
protect it with `|| true`, since the script is run with `set -e`.

The container is started with the `-p` flag to map the host port
to the container port. This flag allows us to "get outside" the
container. We set the environment variable `$HTTPD_PORT`
to this same value so the `httpd` listens on the port 8000 in
the container, which is then mapped to port 8000 in the host.

As discussed above, the `httpd` runs in foreground but we run
the docker container in background with the `-d` flag. This
gives us control of the process at the host level. We can
use the Docker commands `stop` and `kill` to terminate the
process.

In general, you want a single process running in the Docker container.
You can, of course, run as many processes as you like. However,
this makes process management more difficult. With the
one-process-per-container approach, you can know how
to manage processes without thinking about having to
control processes individually within the container and
then at a global level on the host.

##### Run the Server

The last step is to invoke `run-httpd.sh` to start the server
as a daemon:

```bash
$ bash run-httpd.sh

Container id: b6d7ecafd3cc937b46857a0afe35b04702a22ecae535c899a80bb4271a33c3f4

Point your browser to: http://localhost:8000

Stop with: docker stop httpd
```

If we point our browser at `http://localhost:8000` we see the
output of `hello-world.cgi`:

```text
Hello, World!


You are [::ffff:172.17.42.1].

My uname is Linux b6d7ecafd3cc 4.1.8-100.fc21.x86_64 #1 SMP Tue Sep 22 12:13:06 UTC 2015 x86_64 GNU/Linux.
I'm running busybox httpd/1.24.0.
```

The first line is the `Hello, World!` from the `hello-world.sh`
script. The last line displays the CGI variable `$SERVER_SOFTWARE`,
which shows that we are talking to the Busybox web server.

We also see that the `uname` for the kernel is the host computer.
We verify this by running `uname -a` in on the host:

```bash
$ uname -a
Linux v 4.1.8-100.fc21.x86_64 #1 SMP Tue Sep 22 12:13:06 UTC 2015 x86_64 x86_64 x86_64 GNU/Linux
```

The kernel identifier is the same `4.1.8-100.fc21.x86_64` in both
outputs.

Indeed, the lines are almost identical except for differences between
the Busybox and Fedora `uname` implementations and for the hostname, which is
`v` on the host computer and `b6d7ecafd3cc` in the Docker container.
This hostname is the same as the (shorted) container Id, which we
can see with `docker ps`:

```bash
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
b6d7ecafd3cc        radiasoft/httpd     "/bin/sh -c 'httpd -f"   14 minutes ago      Up 14 minutes       0.0.0.0:8000->8000/tcp   httpd
```

The one line that's a bit strange is the
`You are [::ffff:172.17.42.1]`, which takes us into networking
with Docker.

#### Docker Networking

In order to encapsulate the network inside a container, Docker creates a
virtual ethernet device `docker0` and all traffic is routed to/from the
container via `docker0`. This network allows the container to
operate independently of other ports on the host machine and by default
nothing is forwarded from the host machine into the container.

Docker always configures `docker0` with IP address `172.17.42.1` and
a [16 bit subnet](https://en.wikipedia.org/wiki/IPv4_subnetting_reference).
The IP addresses of the containers vary, but they all share the same
subnet on the host so they can be configured to talk to one another.

Docker configures the host's network devices to allow the containers to forward
to the wider world. By default, incoming connections from the wider world are not
forwarded to the `172.42.0.0` subnet. You have to tell Docker to forward
specific ports to the container as we did in `run-httpd.sh`. (Actually, there are
[many network options](https://docs.docker.com/articles/networking/).)

When you do this, Docker sets up a proxy that listens on the host port
(`8000`) and forwards connections to the container port (also
`8000`). This is why you see `172.17.42.1` as the `$REMOTE_ADDR`
output by `hello-world.cgi` above. That's the address of the proxy.

### TODO

Lots to talk about that's important to the general understanding of Docker.

* mapped volumes
* 100% Reproducible Builds
* Simple scripts
* commit/export/import
* cleaning up (rm and rmi)
* minimal image (what an image is really)
* touching root files in the container's mapped volumes
