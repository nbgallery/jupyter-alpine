#!/bin/bash -e

function usage {
  echo "Usage: `basename $0` image_tag [kernel1 kernel2 ...]"
  exit
}

SRCDIR=`dirname $0`
if [ -z "$1" ]; then
  usage
fi

for arg in $@; do
  if [[ "$arg" = "-h" || "$arg" == "--help" ]]; then
    usage
  fi
done

TAG=$1
shift

for kernel in $@; do
  if [ ! -d $SRCDIR/$kernel ]; then
    echo "Kernel subdir $SRCDIR/$kernel not found"
    usage
  fi
  if [ ! -e $SRCDIR/$kernel/Dockerfile.partial ]; then
    echo "Docker file $SRCDIR/$kernel/Dockerfile.partial not found"
    usage
  fi
done

cp -r $SRCDIR/Dockerfile $SRCDIR/Dockerfile.tmp
for kernel in $@; do
  echo "Adding $kernel to Dockerfile"
  cat $SRCDIR/$kernel/Dockerfile.partial >> $SRCDIR/Dockerfile.tmp
done

echo "Building image"
docker build -t $TAG -f $SRCDIR/Dockerfile.tmp $SRCDIR

rm -f $SRCDIR/Dockerfile.tmp

