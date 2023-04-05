#!/bin/bash

modules=(
  './flatpak/install.sh'
  './mirrors/configure.sh'
  './pacman/configure.sh'
  './paru/install.sh'
)

for module in "${modules[@]}" ; do
  source $(realpath $module)
done
