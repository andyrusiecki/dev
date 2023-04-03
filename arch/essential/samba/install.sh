#!/bin/bash

install_samba() {
  label=samba

  # https://wiki.archlinux.org/title/Samba
  log $label "Installing dependencies..."
  install_packages samba avahi

  log $label "Creating configuration..."
  sudo mkdir /etc/samba
  sudo cp $(realpath ./smb.conf) /etc/samba/

  log $label "Enabling systemd services..."
  sudo systemctl enable --now smb.service
  sudo systemctl enable --now nmb.service
  sudo systemctl enable --now avahi-daemon.service

  if command_exists firewall-cmd ; then
    log $label "Adding services to firewalld..."
    firewall-cmd --permanent --add-service={samba,samba-client,samba-dc} --zone=home
  else
    log $label "No firewall service detected... skipping"
  fi

  log $label "Complete"
}
