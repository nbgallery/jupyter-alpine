FROM alpine:3.5
MAINTAINER team@nb.gallery

########################################################################
# Set up OS
########################################################################

EXPOSE 80 443
WORKDIR /root

ENV CPPFLAGS=-s \
    SHELL=/bin/bash

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["jupyter-notebook-secure"]

COPY util/* /usr/local/bin/
COPY config/bashrc /root/.bashrc
COPY patches /root/.patches
COPY config/repositories /etc/apk/repositories
COPY config/*.rsa.pub /etc/apk/keys/

RUN \
  min-apk binutils && \
  min-apk -u zlib && \
  min-apk \
    bash \
    bzip2 \
    curl \
    file \
    gcc \
    g++ \
    git \
    libressl \
    libsodium-dev \
    make \
    openssh-client \
    patch \
    readline-dev \
    tar \
    tini && \
  echo "### Install specific version of zeromq from source" && \
  min-package https://archive.org/download/zeromq_4.0.4/zeromq-4.0.4.tar.gz && \
  ln -s /usr/local/lib/libzmq.so.3 /usr/local/lib/libzmq.so.4 && \
  strip --strip-unneeded --strip-debug /usr/local/bin/curve_keygen && \
  echo "### Alpine compatibility patch for various packages" && \
  if [ ! -f /usr/include/xlocale.h ]; then echo '#include <locale.h>' > /usr/include/xlocale.h; fi && \
  echo "### Cleanup unneeded files" && \
  clean-terminfo && \
  rm /bin/bashbug && \
  rm /usr/local/share/man/*/zmq* && \
  rm -rf /usr/include/c++/*/java && \
  rm -rf /usr/include/c++/*/javax && \
  rm -rf /usr/include/c++/*/gnu/awt && \
  rm -rf /usr/include/c++/*/gnu/classpath && \
  rm -rf /usr/include/c++/*/gnu/gcj && \
  rm -rf /usr/include/c++/*/gnu/java && \
  rm -rf /usr/include/c++/*/gnu/javax && \
  rm /usr/libexec/gcc/x86_64-alpine-linux-musl/*/cc1obj && \
  rm /usr/bin/gcov* && \
  rm /usr/bin/gprof && \
  rm /usr/bin/*gcj


########################################################################
# Install Python2, Jupyter, ipydeps
########################################################################

COPY config/jupyter /root/.jupyter/

# TODO: decorator conflicts with the c++ kernel apk, which we are
# having trouble re-building.  Just let pip install it for now.
#    py2-decorator \

RUN \
  min-apk \
    libffi-dev \
    py2-pygments \
    py2-cffi \
    py2-cryptography \
    py2-jinja2 \
    py2-openssl \
    py2-pexpect \
    py2-pip \
    py2-tornado \
    python \
    python-dev && \
  pip install --no-cache-dir --upgrade setuptools pip && \
  mkdir -p `python -m site --user-site` && \
  min-pip jupyter ipywidgets==6.0.1 jupyter_dashboards pypki2 ipydeps ordo && \
  jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
  pip install http://github.com/nbgallery/nbgallery-extensions/tarball/master#egg=jupyter_nbgallery && \
  jupyter serverextension enable --py jupyter_nbgallery && \
  jupyter nbextension install --py jupyter_nbgallery && \
  jupyter nbextension enable jupyter_nbgallery --py && \
  jupyter dashboards quick-setup --sys-prefix && \
  jupyter nbextension install --py ordo && \
  jupyter nbextension enable ordo --py && \
  echo "### Cleanup unneeded files" && \
  rm -rf /usr/lib/python2*/*/tests && \
  rm -rf /usr/lib/python2*/ensurepip && \
  rm -rf /usr/lib/python2*/idlelib && \
  rm /usr/lib/python2*/distutils/command/*exe && \
  rm -rf /usr/share/man/* && \
  clean-pyc-files /usr/lib/python2* && \
  echo "### Apply patches" && \
  cd / && \
  sed -i 's/_max_upload_size_mb = [0-9][0-9]/_max_upload_size_mb = 50/g' \
    /usr/lib/python2*/site-packages/notebook/static/tree/js/notebooklist.js \
    /usr/lib/python2*/site-packages/notebook/static/tree/js/main.min.js \
    /usr/lib/python2*/site-packages/notebook/static/tree/js/main.min.js.map && \
  patch -p0 < /root/.patches/ipykernel_displayhook && \
  patch -p0 < /root/.patches/websocket_keepalive


########################################################################
# Install python3 kernel
########################################################################

RUN \
  min-apk \
    libffi-dev \
    py3-cffi \
    py3-cparser \
    py3-cryptography \
    py3-dateutil \
    py3-decorator \
    py3-jinja2 \
    py3-openssl \
    py3-ptyprocess \
    py3-six \
    py3-tornado \
    py3-zmq \
    python3 \
    python3-dev && \
  pip3 install --no-cache-dir --upgrade setuptools pip && \
  min-pip3 entrypoints ipykernel ipywidgets==6.0.1 pypki2 ipydeps && \
  echo "### Make sure python2 is still default" && \
  sed -i -r -e 's/python3(\.\d)?/python2/g' \
    /usr/bin/jupyter* \
    /usr/bin/ipython \
    /usr/bin/iptest \
    /usr/bin/pip \
    /usr/bin/easy_install && \
  echo "### Cleanup unneeded files" && \
  rm -rf /usr/lib/python3*/*/tests && \
  rm -rf /usr/lib/python3*/ensurepip && \
  rm -rf /usr/lib/python3*/idlelib && \
  rm -rf /usr/share/man/* && \
  clean-pyc-files /usr/lib/python3*

	
########################################################################
# Add dynamic kernels
########################################################################

ADD kernels /usr/share/jupyter/kernels/
ENV JAVA_HOME=/usr/lib/jvm/default-jvm \
    SPARK_HOME=/usr/spark \
    GOPATH=/go
ENV PATH=$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:$GOPATH/bin:/usr/share/jupyter/kernels/installers \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server


########################################################################
# Add simple kernels (no extra apks)
########################################################################

RUN \
  min-pip bash_kernel jupyter_c_kernel==1.0.0 && \
  python -m bash_kernel.install && \
  clean-pyc-files /usr/lib/python2*


########################################################################
# Metadata
########################################################################

ENV NBGALLERY_CLIENT_VERSION=6.0.6

LABEL gallery.nb.version=$NBGALLERY_CLIENT_VERSION \
      gallery.nb.description="Minimal alpine-based Jupyter notebook server" \
      gallery.nb.URL="https://github.com/nbgallery"
