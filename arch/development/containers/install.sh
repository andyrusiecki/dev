#!/bin/bash

install_containers() {
  label=containers

  log $label "Installing dependencies..."
  install_packages podman podman-docker docker-compose

  log $label "Updating configuration..."
  mkdir -p ~/.config/containers/
  cp $(realpath ./containers.conf) ~/.config/containers/
  cp $(realpath ./registries.conf) ~/.config/containers/

  log $label "Enabling systemd services..."
  sudo systemctl enable --now podman.socket

  log $label "Complete"
}
