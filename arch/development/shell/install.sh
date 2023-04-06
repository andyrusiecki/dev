#!/bin/bash

install_shell() {
  label=shell

  log $label "Installing dependencies..."
  install_packages fish starship python-pywal

  log $label "Updating configuration..."
  mkdir -p ~/.config/fish/
  cp $(realpath ./config.fish) ~/.config/fish/
  cp $(realpath ./starship.toml) ~/.config/

  log $label "Setting new default shell..."
  chsh -s $(command -v fish)

  log $label "Complete"
}
