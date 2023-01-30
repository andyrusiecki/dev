#!/bin/sh

if [ "$1" = "" ]; then
  echo "Argument for Toolbox name is required!"
  exit 0
fi

podman build -t dev-toolbox .
toolbox create -i dev-toolbox $1
