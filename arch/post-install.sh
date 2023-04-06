#!/bin/bash

while getopts 'hd:p:' opt; do
  case "$opt" in
    d)
      arg="$OPTARG"
      if [[ "$arg" == "framework" ]]; then
        DEVICE="$arg"
      fi
      ;;

    p)
      arg="$OPTARG"
      if [[ "$arg" == "gnome" || "$arg" == "hyprland" ]]; then
        PROFILE="$arg"
      fi
      ;;

    ?|h)
      echo "Usage: $(basename $0) [-v] [-d device] [-p profile]"
      echo -e "-d <device>\t runs additional tasks based on the device (available devices: framework)"
      echo -e "-p <profile>\t runs additional tasks based on the profile (available profiles: gnome hyprland)\n"
      exit 1
      ;;
  esac
done

# helper functions
command_exists() {
  command -v "$1" &> /dev/null
}

package_installed() {
  pacman -Qs $1 &> /dev/null
}

install_packages() {
  cmd="sudo pacman"

  if command_exists paru; then
    cmd=paru
  fi

  $cmd -S --noconfirm --needed $@
}

log() {
  label=$1
  msg=$2

  echo -e "[$label] $msg"
}

# desktop
install_fonts() {
  label=fonts

  log $label "Installing dependencies..."
  install_packages ttf-sourcecodepro-nerd ttf-roboto-mono-nerd ttf-meslo-nerd ttf-jetbrains-mono-nerd ttf-hack-nerd ttf-ms-fonts

  log $label "Complete"
}

# development
install_containers() {
  label=containers

  log $label "Installing dependencies..."
  install_packages podman podman-docker docker-compose

  log $label "Updating configuration..."
  mkdir -p ~/.config/containers/
  cp $(realpath ./assets/containers.conf) ~/.config/containers/
  cp $(realpath ./assets/registries.conf) ~/.config/containers/

  log $label "Enabling systemd services..."
  sudo systemctl enable --now podman.socket

  log $label "Complete"
}

install_shell() {
  label=shell

  log $label "Installing dependencies..."
  install_packages fish starship python-pywal

  log $label "Updating configuration..."
  mkdir -p ~/.config/fish/
  cp $(realpath ./assets/config.fish) ~/.config/fish/
  cp $(realpath ./assets/starship.toml) ~/.config/

  log $label "Setting new default shell..."
  chsh -s $(command -v fish)

  log $label "Complete"
}

# device
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
  sudo cp $(realpath ./assets/framework-als-deactivate.conf) /etc/modprobe.d/
  sudo cp $(realpath ./assets/framework-psr-disable.conf) /etc/modprobe.d/

  log $label "Complete"
}

# essential
install_base() {
  label=base

  log $label "Installing base dependencies..."
  install_packages nano vim openssh htop wget iwd wireless_tools wpa_supplicant smartmontools xdg-utils git

  log $label "Complete"
}

install_firewall() {
  # https://wiki.archlinux.org/title/Firewalld
  label=firewall

  log $label "Installing dependencies..."
  install_packages firewalld

  log $label "Enabling systemd services..."
  sudo systemctl enable --now firewalld.service

  log $label "Complete"
}

install_printing() {
  # https://wiki.archlinux.org/title/CUPS
  label=printing

  log $label "Installing dependencies..."
  install_packages cups cups-pdf

  log $label "Enabling systemd services..."
  sudo systemctl enable --now cups.service

  log $label "Complete"
}

install_samba() {
  # https://wiki.archlinux.org/title/Samba
  label=samba

  log $label "Installing dependencies..."
  install_packages samba avahi

  log $label "Creating configuration..."
  sudo mkdir /etc/samba
  sudo cp $(realpath ./assets/smb.conf) /etc/samba/

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

# package management
install_flatpak() {
  # https://wiki.archlinux.org/title/Flatpak
  label=flatpak

  log $label "Installing dependencies..."
  install_packages flatpak

  log $label "Complete"
}

configure_mirrors() {
  # https://wiki.archlinux.org/title/Reflector
  label=mirrors

  msg="Installing reflector for mirrorlist updates..."
  if package_installed reflector ; then
    log $label "$msg skipping"
  else
    log $label $msg
    install_packages reflector
  fi

  log $label "Updating mirrorlist configuration..."

  log $label "Set Country to \"United States\"..."
  sudo sed -i '/^# --country=/s/^.*$/--country="United States"/' /etc/xdg/reflector/reflector.conf

  log $label "Enabling systemd services..."
  sudo systemctl enable --now reflector.service

  log $label "Complete"
}

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
  cp $(realpath ./assets/paru.conf) ~/.config/paru/

  log $label "Complete"
}

post_install() {
  echo -e "Starting Arch Post-Install Tasks...\n"

  configure_mirrors
  configure_pacman
  install_base
  install_paru
  # TODO: desktop here (need xdg-desktop-portal before flatpak)
  install_fonts
  install_firewall
  install_printing
  install_samba
  install_sound
  install_shell
  install_containers

  if [[ "$DEVICE" == "framework" ]]; then
    install_device_framework
  fi

  echo -e "\nArch Post-Install Tasks Complete!"
}

TIMEFORMAT="Total Time: %0lR"
time post_install

