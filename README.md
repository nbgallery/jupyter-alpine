# jupyter-docker

This is a minimal docker image (currently 230 MB) for running the Jupyter notebook server.  It is hosted on [Docker Hub](https://hub.docker.com/r/nbgallery/jupyter-alpine/).

The small size is achieved by using the Alpine Linux base image and by installing language kernels on the fly.  We currently support about a dozen languages, but only Python 2 is baked into the image.  The other kernels are packaged into [apks](https://github.com/nbgallery/apks) that get [installed](kernels/installers) on first use.
