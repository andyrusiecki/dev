#!/bin/bash

modules=(
  './framework/install.sh'
)

for module in "${modules[@]}" ; do
  source $(realpath $module)
done
