#!/bin/bash

modules=(
  './containers/install.sh'
  './shell/install.sh'
)

for module in "${modules[@]}" ; do
  source $(realpath $module)
done
