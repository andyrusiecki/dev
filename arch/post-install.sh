#!/bin/bash

source $(realpath ./package-management/mirrors/configure.sh)
source $(realpath ./package-management/pacman/configure.sh)
source $(realpath ./package-management/paru/install.sh)
source $(realpath ./essential/samba/install.sh)

! [ -n "$UTIL_SOURCED" ] && source $(realpath ./util.sh)

modules=(
  'configure_mirrors'
  'configure_pacman'
  'install_paru'
  'install_samba'
)

for cmd in "${modules[@]}" ; do
  $cmd
done

log "ALL" "Complete!"
