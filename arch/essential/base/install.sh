#!/bin/bash

install_base() {
  # https://wiki.archlinux.org/title/Firewalld
  label=base

  log $label "Installing base dependencies..."
  install_packages nano vim openssh htop wget iwd wireless_tools wpa_supplicant smartmontools xdg-utils git

  log $label "Complete"
}
