#!/bin/bash

source $(realpath ./util.sh)
source $(realpath ./development/all.sh)
source $(realpath ./device/all.sh)
source $(realpath ./essential/all.sh)
source $(realpath ./package-management/all.sh)

post_install() {
  echo -e "Starting Arch Post-Install Tasks...\n"

  configure_mirrors
  configure_pacman
  install_base
  install_paru
  # TODO: desktop here (need xdg-desktop-portal before flatpak)
  install_firewall
  install_printing
  install_samba
  install_sound
  install_shell
  install_containers
  # TODO: device here

  echo -e "\nArch Post-Install Tasks Complete!"
}

TIMEFORMAT="Total Time: %0lR"
time post_install

