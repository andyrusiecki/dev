#!/bin/bash

source $(realpath ./essential/samba/install.sh)
! [ -n "$UTIL_SOURCED" ] && source $(realpath ./util.sh)

modules=(
  'install_samba'
)

for cmd in "${modules[@]}" ; do
  $cmd
done

log "ALL" "Complete!"
