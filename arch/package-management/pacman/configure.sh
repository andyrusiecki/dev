#!/bin/bash

configure_pacman() {
  # https://man.archlinux.org/man/pacman.conf.5
  label=pacman

  log $label "Updating pacman configuration..."

  log $label "Enabling ParallelDownloads..."
  sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

  log $label "Enabling multilib repo..."
  sudo sed -i '/\[multilib\]/,+1 s/#//' /etc/pacman.conf

  log $label "Complete"
}
