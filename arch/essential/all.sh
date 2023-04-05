#!/bin/bash

modules=(
  './base/install.sh'
  './firewall/install.sh'
  './printing/install.sh'
  './samba/install.sh'
  './sound/install.sh'
)

for module in "${modules[@]}" ; do
  source $(realpath $module)
done
