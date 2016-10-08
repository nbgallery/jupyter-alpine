#!/usr/bin/env bash

min-apk gallery-toree-kernel
jupyter toree install --kernel_name='Spark' --interpreters=Scala,PySpark,SparkR,SQL

if [ apk info gallery-toree-kernel &> /dev/null ]; then
  exec $0 "$@"
else
  echo "Installation failed!"
fi
