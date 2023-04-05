#!/bin/bash

install_device_framework() {
  # https://wiki.archlinux.org/title/Framework_Laptop
  label=device-framework

  log $label "Installing Intel graphics drivers..."
  install_packages mesa libva-intel-driver intel-media-driver vulkan-intel

  log $label "Installing fingerprint reader dependencies..."
  install_packages fprintd imagemagick

  log $label "Installing power management dependencies..."
  install_packages power-profiles-daemon

  log $label "Adding kernel parameters..."
  sudo cp $(realpath ./framework-als-deactivate.conf) /etc/modprobe.d/
  sudo cp $(realpath ./framework-psr-disable.conf) /etc/modprobe.d/

  log $label "Complete"
}
