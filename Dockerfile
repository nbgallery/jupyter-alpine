FROM alpine
MAINTAINER jupyter-gallery


############################################
# Set up OS
############################################
EXPOSE 80
WORKDIR /root

ENV \
  CPPFLAGS=-s \
  SHELL=/bin/bash

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["jupyter", "notebook"]

RUN \
  echo "http://nl.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories && \
  echo "http://nl.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
  echo "http://dl-4.alpinelinux.org/alpine/edge/testing/" >> /etc/apk/repositories

COPY util/* /usr/local/bin/
RUN min-apk \
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
  rm /usr/libexec/gcc/x86_64-alpine-linux-musl/5.3.0/cc1obj && \
  rm /usr/bin/gcov* /usr/bin/gprof

RUN min-package http://download.zeromq.org/zeromq-4.0.4.tar.gz


############################################
# Install Python2
############################################
RUN min-apk \
  python \
  python-dev  \
  py-pip
#COPY config/pip.conf /etc/pip.conf


############################################
# Install Jupyter
############################################
RUN min-pip notebook ipywidgets
COPY config/jupyter /root/.jupyter/
#COPY *.ipynb /root/


############################################
# Install Ruby
############################################
ENV \
  RUBY_GC_HEAP_GROWTH_FACTOR=1.1 \
  RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.1 \
  RUBY_GC_OLDMALLOC_LIMIT_GROWH_FACTOR=1.1 \
  RUBY_GC_OLDMALLOC_LIMIT=16000100 \
  RUBY_GC_OLDMALLOC_LIMIT_MAX=16000100 \
  RUBY_GC_MALLOC_LIMIT=4000100 \
  RUBY_GC_MALLOC_LIMIT_MAX=16000100

RUN min-apk libffi-dev ruby ruby-dev
COPY config/gemrc /etc/gemrc
RUN min-gem \
  ffi-rzmq \
  io-console \
  iruby:0.2.8 \
  pry
RUN iruby register


############################################
# Install patches
############################################
COPY patches /root/patches/
RUN for i in /root/patches/*; do (cd / && patch -b -p0) < $i; done && rm -r /root/patches

