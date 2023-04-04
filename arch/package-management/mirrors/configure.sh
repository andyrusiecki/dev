#!/bin/bash

configure_mirrors() {
  # https://wiki.archlinux.org/title/Reflector
  label=mirrors

  msg="Installing reflector for mirrorlist updates..."
  if package_installed reflector ; then
    log $label "$msg skipping"
  else
    log $label $msg
    install_packages reflector
  fi

  log $label "Updating mirrorlist configuration..."

  log $label "Set Country to \"United States\"..."
  sudo sed -i '/^# --country=/s/^.*$/--country="United States"/' /etc/xdg/reflector/reflector.conf

  log $label "Enabling systemd services..."
  sudo systemctl enable --now reflector.service

  log $label "Complete"
}
