#!/bin/bash

install_paru() {
  # https://github.com/Morganamilo/paru
  label=paru

  msg="Installing paru..."
  if command_exists paru ; then
    log $label "$msg skipping"
  else
    log $label $msg
    tmp_dir=$(mktemp -d)

    git clone https://aur.archlinux.org/paru.git $tmp_dir/paru

    (cd $tmp_dir/paru && makepkg --noconfirm --needed -si)

    rm -rf $tmp_dir
  fi

  msg="Installing bat for PKGBUILD syntax highlighting..."
  if package_installed bat ; then
    log $label "$msg skipping"
  else
    log $label $msg
    install_packages bat
  fi

  log $label "Creating configuration..."
  mkdir -p ~/.config/paru
  cp $(realpath ./paru.conf) ~/.config/paru/

  log $label "Complete"
}
