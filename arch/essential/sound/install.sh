#!/bin/bash

install_sound() {
  # taken from archinstall
  # https://github.com/archlinux/archinstall/blob/master/profiles/applications/pipewire.py
  label=sound

  log $label "Installing dependencies..."
  install_packages pipewire pipewire-alsa pipewire-jack pipewire-pulse gst-plugin-pipewire libpulse wireplumber

  log $label "Enabling systemd services..."
  sudo systemctl enable --user pipewire-pulse.service

  log $label "Complete"
}
