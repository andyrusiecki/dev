#!/bin/bash

install_samba() {
  # https://wiki.archlinux.org/title/Samba
  label=samba

  log $label "Installing dependencies..."
  install_packages samba avahi

  log $label "Creating configuration..."
  sudo mkdir /etc/samba
  sudo cp $(realpath ./smb.conf) /etc/samba/

  log $label "Enabling systemd services..."
  sudo systemctl enable --now smb.service
  sudo systemctl enable --now nmb.service
  sudo systemctl enable --now avahi-daemon.service

  ## This may not be needed
  # if command_exists firewall-cmd ; then
  #   log $label "Adding services to firewalld..."
  #   firewall-cmd --permanent --add-service={samba,samba-client,samba-dc} --zone=home
  # else
  #   log $label "No firewall service detected... skipping"
  # fi

  log $label "Complete"
}