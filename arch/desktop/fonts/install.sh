#!/bin/bash

install_fonts() {
  label=fonts

  log $label "Installing dependencies..."
  install_packages ttf-sourcecodepro-nerd ttf-roboto-mono-nerd ttf-meslo-nerd ttf-jetbrains-mono-nerd ttf-hack-nerd ttf-ms-fonts

  log $label "Complete"
}
