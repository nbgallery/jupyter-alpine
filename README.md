# jupyter-docker

[![Project Status: Unsupported – We are migrating off of Alpine onto Project Jupyter's base image.  See our new repo at https://github.com/nbgallery/docker-images](https://www.repostatus.org/badges/latest/unsupported.svg)](https://www.repostatus.org/#unsupported)

## Overview

This is a minimal [Alpine](https://alpinelinux.org/)-based [docker](https://www.docker.com/) image for running the Jupyter notebook server.  It is designed for constrained environments in which the size of the docker image is a major consideration.  The latest version (7.x series) is about 340MB uncompressed, much smaller than the official Jupyter images.  It is hosted on [Docker Hub](https://hub.docker.com/r/nbgallery/jupyter-alpine/).

We achieve the small image size by using the Alpine Linux base image, minimizing the number of pre-installed Python packages, and installing other language kernels on the fly.  We currently support about a dozen languages, but only Python 2 and 3 are baked into the image.  The other kernels are built into [Alpine packages (apks)](https://github.com/nbgallery/apks) that get [installed](kernels/installers) on first use.  We also build popular Python data science packages into pre-compiled apks that can be installed using the [ipydeps](https://github.com/nbgallery/ipydeps) [dependencies mechanism](https://github.com/nbgallery/ipydeps#dependencieslink).

For more information, please check out [this post](https://nbgallery.github.io/Jupyter-Docker.html) on our [github.io](https://nbgallery.github.io) site.

## Repository Status

We are migrating off of this Alpine-based docker image onto Project Jupyter's [base image](https://github.com/jupyter/docker-stacks/tree/master/base-notebook).  Please see our new repo at https://github.com/nbgallery/docker-images.

Why move away from Alpine?  Three main reasons:

 * Our organization's docker orchestration environment originally had image size restrictions, but those have since been relaxed.  Meanwhile, the official Jupyter image has gotten smaller, and we'd prefer to build off of the same image as the rest of the community.
 * Alpine's Python package support is not great.  Packages with native code take a while to install, and some don't build on Alpine at all.  Alpine maintains pre-compiled packages such as [py3-numpy](https://pkgs.alpinelinux.org/package/v3.10/community/x86_64/py3-numpy), but they're not always up-to-date and pip doesn't know about them (which motivated [this feature](https://github.com/nbgallery/ipydeps#dependenciesjson) in `ipydeps`).
 * Alpine's package repository is not as complete as other Linux distributions.  We've been maintaining some of [our own packages](https://github.com/nbgallery/apks), and we'd prefer to get out of that business.

## Installation

Remember that docker commands usually need to be run as root or via sudo.

You can pull the image from Docker Hub: 

```
docker pull nbgallery/jupyter-alpine
```

To build the image from source, clone or download the repo.  Then build with something like this:

```
docker build -t nbgallery/jupyter-alpine:<version> <source-directory>
```

## Running the image

You will usually launch a container something like this:

```
docker run --rm -p 443:443 nbgallery/jupyter-alpine
```

The default entrypoint is [jupyter-notebook-secure](util/jupyter-notebook-secure), which will generate a self-signed certificate and then launch the jupyter notebook server under HTTPS with an automatically-generated [authentication token](http://jupyter-notebook.readthedocs.io/en/stable/security.html).
