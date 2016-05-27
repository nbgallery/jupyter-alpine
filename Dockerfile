FROM alpine
MAINTAINER https://github.com/jupyter-gallery


############################################
# Set up OS
############################################
EXPOSE 80
WORKDIR /root

ENV \
  CPPFLAGS=-s \
  SHELL=/bin/bash

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["jupyter", "notebook"]

COPY util/* /usr/local/bin/
COPY config/bashrc /root/.bashrc
COPY patches /root/.patches
RUN \
  echo "http://dl-3.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories && \
  echo "http://dl-3.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
  echo "http://dl-3.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
  echo "http://dl-4.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories && \
  echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
  echo "http://dl-4.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
  echo "http://nl.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories && \
  echo "http://nl.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
  echo "http://nl.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
  min-apk \
    bash \
    bzip2 \
    curl \
    file \
    gcc \
    g++ \
    make \
    openssh-client \
    patch \
    readline-dev \
    tar \
    tini && \
  min-package http://download.zeromq.org/zeromq-4.0.4.tar.gz && \
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


############################################
# Install Python2 & Jupyter
############################################
COPY config/jupyter /root/.jupyter/
#COPY config/pip.conf /etc/pip.conf # if desired
#COPY *.ipynb /root/ # if desired
RUN \
  min-apk python python-dev py-pip && \
  min-pip notebook ipywidgets && \
  cd / && \
  patch -p0 < /root/.patches/websocket_keepalive && \
  clean-py-files /usr/lib/python2*


