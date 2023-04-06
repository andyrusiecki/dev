#!/bin/bash

modules=(
  './fonts/install.sh'
)

for module in "${modules[@]}" ; do
  source $(realpath $module)
done
