#!/bin/bash

command_exists() {
  command -v "$1" &> /dev/null
}

package_installed() {
  pacman -Qs $1 &> /dev/null
}

install_packages() {
  cmd="sudo pacman"

  if command_exists paru; then
    cmd=paru
  fi

  $cmd -S --noconfirm --needed $@
}

log() {
  label=$1
  msg=$2

  echo -e "[$label] $msg"
}
