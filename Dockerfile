FROM alpine:3.8

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
  min-apk \
    bash \
    bzip2 \
    ca-certificates \
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
    tini \
    wget && \
  echo "### Install specific version of zeromq from source" && \
  min-package https://archive.org/download/zeromq_4.0.4/zeromq-4.0.4.tar.gz && \
  ln -s /usr/local/lib/libzmq.so.3 /usr/local/lib/libzmq.so.4 && \
  strip --strip-unneeded --strip-debug /usr/local/bin/curve_keygen && \
  echo "### Alpine compatibility patch for various packages" && \
  if [ ! -f /usr/include/xlocale.h ]; then echo '#include <locale.h>' > /usr/include/xlocale.h; fi && \
  echo "### Cleanup unneeded files" && \
  clean-terminfo && \
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
# Install python2 kernel
########################################################################

RUN \
  min-apk \
    py2-cffi \
    py2-cparser \
    py2-cryptography \
    py2-dateutil \
    py2-decorator \
    py2-jinja2 \
    py2-openssl \
    py2-pip \
    py2-ptyprocess \
    py2-six \
    py2-tornado \
    py2-zmq \
    python2 \
    python2-dev && \
  pip install --no-cache-dir --upgrade setuptools pip && \
  min-pip2 entrypoints notebook==5.2.2 ipykernel ipywidgets==6.0.1 pypki2 ipydeps && \
  echo "### Cleanup unneeded files" && \
  rm -rf /usr/lib/python2*/*/tests && \
  rm -rf /usr/lib/python2*/ensurepip && \
  rm -rf /usr/lib/python2*/idlelib && \
  rm -rf /usr/share/man/* && \
  clean-pyc-files /usr/lib/python2*


########################################################################
# Install Python3, Jupyter, ipydeps
########################################################################

COPY config/jupyter /root/.jupyter/
COPY config/ipydeps /root/.config/ipydeps/

# TODO: decorator conflicts with the c++ kernel apk, which we are
# having trouble re-building.  Just let pip install it for now.
#    py3-decorator \

RUN \
  min-apk \
    libffi-dev \
    py3-pygments \
    py3-cffi \
    py3-cryptography \
    py3-jinja2 \
    py3-openssl \
    py3-pexpect \
    py3-tornado \
    python3 \
    python3-dev && \
  pip3 install --no-cache-dir --upgrade setuptools pip && \
  mkdir -p `python -m site --user-site` && \
  min-pip3 notebook==5.2.2 jupyter ipywidgets==6.0.1 jupyter_dashboards pypki2 ipydeps ordo jupyter_nbgallery && \
  echo "### Install jupyter extensions" && \
  jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
  jupyter serverextension enable --py jupyter_nbgallery && \
  jupyter nbextension install --py jupyter_nbgallery && \
  jupyter nbextension enable jupyter_nbgallery --py && \
  jupyter dashboards quick-setup --sys-prefix && \
  jupyter nbextension install --py ordo && \
  jupyter nbextension enable ordo --py && \
  echo "### Cleanup unneeded files" && \
  rm -rf /usr/lib/python3*/*/tests && \
  rm -rf /usr/lib/python3*/ensurepip && \
  rm -rf /usr/lib/python3*/idlelib && \
  rm -f /usr/lib/python3*/distutils/command/*exe && \
  rm -rf /usr/share/man/* && \
  clean-pyc-files /usr/lib/python3* && \
  echo "### Apply patches" && \
  cd / && \
  sed -i 's/_max_upload_size_mb = [0-9][0-9]/_max_upload_size_mb = 50/g' \
    /usr/lib/python3*/site-packages/notebook/static/tree/js/notebooklist.js \
    /usr/lib/python3*/site-packages/notebook/static/tree/js/main.min.js \
    /usr/lib/python3*/site-packages/notebook/static/tree/js/main.min.js.map && \
  patch -p0 < /root/.patches/ipykernel_displayhook && \
  patch -p0 < /root/.patches/websocket_keepalive


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
  min-pip3 bash_kernel jupyter_c_kernel==1.0.0 && \
  python3 -m bash_kernel.install && \
  clean-pyc-files /usr/lib/python3*


########################################################################
# Metadata
########################################################################

ENV NBGALLERY_CLIENT_VERSION=7.8.4

LABEL gallery.nb.version=$NBGALLERY_CLIENT_VERSION \
      gallery.nb.description="Minimal alpine-based Jupyter notebook server" \
      gallery.nb.URL="https://github.com/nbgallery" \
      maintainer="https://github.com/nbgallery"
