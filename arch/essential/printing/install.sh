#!/bin/bash

install_printing() {
  # https://wiki.archlinux.org/title/CUPS
  label=printing

  log $label "Installing dependencies..."
  install_packages cups cups-pdf

  log $label "Enabling systemd services..."
  sudo systemctl enable --now cups.service

  log $label "Complete"
}
