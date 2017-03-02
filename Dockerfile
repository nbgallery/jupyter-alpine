FROM alpine
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
# Install Python2 & Jupyter
########################################################################

COPY config/jupyter /root/.jupyter/

RUN \
  min-apk \
    libffi-dev \
    py2-pygments \
    py2-cffi \
    py2-cryptography \
    py2-decorator \
    py2-jinja2 \
    py2-openssl \
    py2-pexpect \
    py2-pip \
    py2-tornado \
    python \
    python-dev && \
  pip install --no-cache-dir --upgrade setuptools pip && \
  mkdir -p `python -m site --user-site` && \
  min-pip jupyter ipywidgets jupyterlab && \
  jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
  pip install http://github.com/nbgallery/nbgallery-extensions/tarball/master#egg=jupyter_nbgallery && \
  jupyter serverextension enable --py jupyter_nbgallery && \
  jupyter nbextension install --py jupyter_nbgallery && \
  jupyter nbextension enable jupyter_nbgallery --py && \
  jupyter serverextension enable --py jupyterlab --sys-prefix && \
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
  patch -p0 < /root/.patches/websocket_keepalive && \
  patch --no-backup-if-mismatch -p0 < /root/.patches/notebook_pr2061 && \
  /root/.patches/sed_for_pr2061

########################################################################
# Install ipydeps
########################################################################

RUN \
  pip install http://github.com/nbgallery/pypki2/tarball/master#egg=pypki2 && \
  pip install http://github.com/nbgallery/ipydeps/tarball/master#egg=ipydeps && \
  clean-pyc-files /usr/lib/python2* && \
  echo "### TODO: applying workaround for https://github.com/nbgallery/ipydeps/issues/7" && \
  sed -i 's/packages = set(packages)/#packages = set(packages)/' /usr/lib/python2*/site-packages/ipydeps/__init__.py
	
########################################################################
# Add dynamic kernels
########################################################################

ADD kernels /usr/share/jupyter/kernels/
ENV JAVA_HOME=/usr/lib/jvm/default-jvm \
    SPARK_HOME=/usr/spark
ENV PATH=$PATH:$JAVA_HOME/bin:$SPARK_HOME/bin:/usr/share/jupyter/kernels/installers \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$JAVA_HOME/jre/lib/amd64/server

########################################################################
# Add Bash kernel
########################################################################

RUN \
  min-pip bash_kernel && \
  python -m bash_kernel.install && \
  clean-pyc-files /usr/lib/python2*

########################################################################
# Metadata
########################################################################

ENV NBGALLERY_CLIENT_VERSION=5.3.0

LABEL gallery.nb.version=$NBGALLERY_CLIENT_VERSION \
      gallery.nb.description="Minimal alpine-based Jupyter notebook server" \
      gallery.nb.URL="https://github.com/nbgallery"
