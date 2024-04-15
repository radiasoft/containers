## Containers for Scientific Codes

RadiaSoft provides the following Open Container Initiative (OCI)
images to support scientific computing.

### Installation

The best way to install is to use our
[automated downloader](https://github.com/radiasoft/download). For example,
to use sirepo:

```sh
mkdir sirepo
cd sirepo
curl https://radia.run | bash
```

If you are running Windows, you will have to run this command in a
virtual machine or use the
[Sirepo development install](https://github.com/radiasoft/sirepo/wiki/Development#pc-install).

### Selecting OCI Run-Time

The default OCI run-time is `docker`, if installed. Otherwise, it will
try `podman`. These are the only run-times supported. If you have both
`docker` and `podman` installed and executable by the current user,
then you can select the runtime by setting `$RADIA_RUN_OCI_CMD`, e.g.
to force `podman`:

```sh
export RADIA_RUN_OCI_CMD=podman
```

### Images

The follow container images are available:

* [radiasoft/beamsim](https://github.com/radiasoft/container-beamsim)
  is a physics image for particle accelerator and free electron laser (FEL) simulations.
* [radiasoft/beamsim-jupyter](https://github.com/radiasoft/container-beamsim-jupyter)
  is a Jupyter/IPython notebook server for beamsim.
* [radiasoft/sirepo](https://github.com/radiasoft/sirepo)
  is an web application to simplify the execution of scientific codes.

### Manifests

All OCI images contain an `/rsmanifest.json` file, which documents
the image: name, type, verison, and uri.

`radiasoft/beamsim` contains the source code for all the beam
simulation codes it installs. All codes are documented in
`/home/vagrant/rsmanifest.json`.

### Build

To build an OCI image, clone the appropriate container repo and run:

```bash
git clone https://github.com/radiasoft/container-beamsim
cd container-beamsim
radia_run container-build
```

The command will finish with instructions how to get the images into
Docker Hub. You can change the registry by exporting
`$RADIA_RUN_OCI_REGISTRY`, e.g. to support
[Red Hat Quay](https://quay.io):


```sh
export RADIA_RUN_OCI_REGISTRY=quay.io
```
