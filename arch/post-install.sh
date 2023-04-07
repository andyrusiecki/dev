#!/bin/bash

while getopts 'hd:p:' opt; do
  case "$opt" in
    d)
      arg="$OPTARG"
      if [[ "$arg" == "vm" || "$arg" == "framework" ]]; then
        device="$arg"
      fi
      ;;

    p)
      arg="$OPTARG"
      if [[ "$arg" == "gnome" || "$arg" == "hyprland" ]]; then
        profile="$arg"
      fi
      ;;

    ?|h)
      echo "Usage: $(basename $0) [-v] [-d device] [-p profile]"
      echo -e "-d <device>\t runs additional tasks based on the device (available devices: vm framework)"
      echo -e "-p <profile>\t runs additional tasks based on the profile (available profiles: gnome hyprland)\n"
      exit 1
      ;;
  esac
done

root=$(dirname $(realpath $0))

packages=(
  # base
  nano
  vim
  openssh
  htop
  wget
  iwd
  wireless_tools
  wpa_supplicant
  smartmontools
  xdg-utils

  # fonts
  noto-fonts
  ttf-sourcecodepro-nerd
  ttf-roboto-mono-nerd
  ttf-meslo-nerd
  ttf-jetbrains-mono-nerd
  ttf-hack-nerd
  ttf-ms-fonts

  # firewall (https://wiki.archlinux.org/title/Firewalld)
  firewalld

  # printing (https://wiki.archlinux.org/title/CUPS)
  cups
  cups-pdf

  # samba (https://wiki.archlinux.org/title/Samba)
  samba
  avahi

  # sound (https://github.com/archlinux/archinstall/blob/master/profiles/applications/pipewire.py)
  pipewire
  pipewire-alsa
  pipewire-jack
  pipewire-pulse
  gst-plugin-pipewire
  libpulse
  wireplumber

  # shell
  fish
  starship
  python-pywal

  # containers
  podman
  podman-docker
  docker-compose

  # flatpak
  flatpak
)
systemd_services_root=(
  # mirrorlist
  reflector.service

  # firewall
  firewalld.service

  # printing
  cups.service

  # samba
  smb.service
  nmb.service
  avahi-daemon.service

  # containers
  podman.socket
)
systemd_services_user=(
  # sound
  pipewire-pulse.service
)

for i in ${systemd_services_root[@]}
do
	echo "systemd: $i"
done
exit 0
echo "Starting Arch Post-Install Tasks..."

# 1. Update pacman config (https://man.archlinux.org/man/pacman.conf.5)
# - enabling parallel downloads (defaults to 5)
sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

# - enabling multilib repo
sudo sed -i '/\[multilib\]/,+1 s/#//' /etc/pacman.conf

# 2. Update package repos and existing packages
sudo pacman -Syu --noconfirm

# 3. Install initial packages
sudo pacman -S --noconfirm --needed bat git reflector

# 4. Update pacman mirrorlist (https://wiki.archlinux.org/title/Reflector)
sudo reflector --save /etc/pacman.d/mirrorlist --protocol https --country "United States" --latest 5 --sort age

# 5. Install paru (https://github.com/Morganamilo/paru)
tmp_dir=$(mktemp -d)
git clone https://aur.archlinux.org/paru.git $tmp_dir/paru
(cd $tmp_dir/paru && makepkg --noconfirm --needed -si)
rm -rf $tmp_dir

# 6. Profile
case $profile in
  gnome)
    packages+=(
      gdm
      gnome
      gnome-bluetooth-3.0
      gnome-boxes
      gnome-shell-extensions
      gnome-sound-recorder
      gnome-tweaks
      gnome-usage
      gst-plugins-good
      xdg-desktop-portal-gnome
      xorg-server
      xorg-xinit
    )

    systemd_services_root+=(
      gdm.service
    )
    ;;

  hyprland)
    packages+=(
      hyprland
      xdg-desktop-portal-hyprland-git
    )

    # TODO: hyprland profile
    ;;
esac

# 7. Device
case $profile in
  vm)
    packages+=(
      mesa
      xf86-video-vmware
    )
    ;;

  framework)
    packages+=(
      # graphics
      mesa
      libva-intel-driver
      intel-media-driver
      vulkan-intel

      # fingerprint reader
      fprintd
      imagemagick

      # power management
      power-profiles-daemon
    )

    # fixing brightness keys
    sudo cp $root/assets/framework-als-deactivate.conf /etc/modprobe.d/

    # fixing screen freezes
    sudo cp $root/assets/framework-psr-disable.conf /etc/modprobe.d/

    # TODO: fprint pam setup
    ;;
esac

# 8. Install packages
paru -S --noconfirm --needed ${packages[@]}

# 9. Copy config files
sudo cp $root/assets/reflector.conf /etc/xdg/reflector/reflector.conf

mkdir -p ~/.config/paru
cp $root/assets/paru.conf ~/.config/paru/

sudo mkdir /etc/samba
sudo cp $root/assets/smb.conf /etc/samba/

mkdir -p ~/.config/fish/
cp $root/assets/config.fish ~/.config/fish/
cp $root/assets/starship.toml ~/.config/

mkdir -p ~/.config/containers/
cp $root/assets/containers.conf ~/.config/containers/
cp $root/assets/registries.conf ~/.config/containers/

# 10. Post install tasks
chsh -s $(command -v fish)

extensions=(
  appindicatorsupport@rgcjonas.gmail.com
  bluetooth-quick-connect@bjarosze.gmail.com
  blur-my-shell@aunetx
  mediacontrols@cliffniff.github.com
  nightthemeswitcher@romainvigier.fr
  no-overview@fthx
  pip-on-top@rafostar.github.com
  user-theme@gnome-shell-extensions.gcampax.github.com
  Vitals@CoreCoding.com
)

if [[ $profile == "gnome" ]]; then
  # TODO: install gnome extensions
fi

# 10. Enable systemd services
for i in ${systemd_services_root[@]}
do
	sudo systemctl enable --now $i
done

for i in ${systemd_services_user[@]}
do
	systemctl enable --now --user $i
done

echo -e "\nArch Post-Install Tasks Complete!\n"
