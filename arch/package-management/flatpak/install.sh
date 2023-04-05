#!/bin/bash

install_flatpak() {
  # https://wiki.archlinux.org/title/Flatpak
  label=flatpak

  log $label "Installing dependencies..."
  install_packages flatpak

  log $label "Complete"
}
