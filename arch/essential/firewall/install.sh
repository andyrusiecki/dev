#!/bin/bash

install_firewall() {
  # https://wiki.archlinux.org/title/Firewalld
  label=firewall

  log $label "Installing dependencies..."
  install_packages firewalld

  log $label "Enabling systemd services..."
  sudo systemctl enable --now firewalld.service

  log $label "Complete"
}
