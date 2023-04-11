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
  linux-lts
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

  # bluetooth
  bluez
  bluez-utils

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

  # boot
  plymouth

  # shell
  fish
  starship
  python-pywal

  # development
  amazon-ecr-credential-helper
  aws-cli-v2
  docker-compose
  go
  jq
  kubectl
  make
  podman
  podman-docker

  # flatpak
  flatpak

  # Other applications
)
systemd_services_root=(
  # snapper
  snapper-cleanup.timer
  snapper-timeline.timer

  # mirrorlist
  reflector.service

  # bluetooth
  bluetooth.service

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
flatpak_apps=(
  # TODO: add apps
)

echo "Starting Arch Post-Install Tasks..."

# 1. Setup snapper and create a snapshot (https://www.reddit.com/r/Fedora/comments/n1ekg0/comment/gwfxvhc/?utm_source=reddit&utm_medium=web2x&context=3)
sudo pacman -S --noconfirm --needed snapper
sudo umount /.snapshots
sudo rm -r /.snapshots
sudo snapper -c root create-config /

sudo snapper -c root create --description "Pre Arch Post-Install Tasks"

# 2. Update pacman config (https://man.archlinux.org/man/pacman.conf.5)
# - enabling parallel downloads (defaults to 5)
sudo sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf

# - enabling multilib repo
sudo sed -i '/\[multilib\]/,+1 s/#//' /etc/pacman.conf

# 3. Update package repos and existing packages
sudo pacman -Syu --noconfirm

# 4. Install initial packages
sudo pacman -S --noconfirm --needed bat git reflector

# 5. Update pacman mirrorlist (https://wiki.archlinux.org/title/Reflector)
sudo reflector --save /etc/pacman.d/mirrorlist --protocol https --country "United States" --latest 5 --sort age

# 6. Install paru (https://github.com/Morganamilo/paru)
tmp_dir=$(mktemp -d)
git clone https://aur.archlinux.org/paru-bin.git $tmp_dir/paru
(cd $tmp_dir/paru && makepkg --noconfirm --needed -si)
rm -rf $tmp_dir

# 7. Profile
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
      adw-gtk3
    )

    systemd_services_root+=(
      gdm.service
    )
    ;;

  hyprland)
    packages+=(
      brightnessctl
      btop
      file-roller
      grim
      gvfs
      hyprland
      kitty
      lxappearance
      mako
      pacman-contrib
      pamixer
      pavucontrol
      polkit-kde-agent
      qt5-wayland
      qt6-wayland
      sddm-git
      slurp
      swappy
      swaylock-effects
      swww
      thunar
      thunar-archive-plugin
      waybar-hyprland
      wlogout
      wofi
      xdg-desktop-portal-hyprland-git
      xfce4-settings
    )

    systemd_services_root+=(
      sddm.service
    )
    ;;
esac

# 8. Device
case $device in
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

    systemd_services_root+=(
      power-profiles-daemon.service
    )
    # fixing brightness keys
    sudo cp $root/assets/framework-als-deactivate.conf /etc/modprobe.d/

    # fixing screen freezes
    sudo cp $root/assets/framework-psr-disable.conf /etc/modprobe.d/

    # TODO: fprint pam setup
    ;;
esac

# 9. Install packages
paru -S --noconfirm --needed ${packages[@]}

# 10 Install flatpak apps
for app in ${flatpak_apps[@]}
do
	flatpak install --noninteractive $app
done

# 11. Copy config files
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

mkdir ~/.docker
cp $root/assets/docker-config.json ~/.docker/config.json

# 12. Post install tasks
chsh -s $(command -v fish)

if [[ $profile == "gnome" ]]; then
  # gnome extensions
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

  shell_version=$(gnome-shell --version | cut -d' ' -f3)

  for uuid in ${extensions[@]}
  do
    info_json=$(curl -sS "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version")
    download_url=$(echo $info_json | jq ".download_url" --raw-output)

    gnome-extensions install "https://extensions.gnome.org$download_url"
    gnome-extensions enable $uuid
  done

  # gnome dconf settings
  gsettings set org.gnome.desktop.datetime automatic-timezone true

  gsettings set org.gnome.desktop.interface clock-format "12h"
  gsettings set org.gnome.desktop.interface clock-show-weekday true
  gsettings set org.gnome.desktop.interface font-antialiasing "rgba"
  gsettings set org.gnome.desktop.interface font-hinting "slight"
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"

  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<SHIFT><SUPER>1']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<SHIFT><SUPER>2']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<SHIFT><SUPER>3']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<SHIFT><SUPER>4']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-5 "['<SHIFT><SUPER>5']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-6 "['<SHIFT><SUPER>6']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-7 "['<SHIFT><SUPER>7']"
  gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-8 "['<SHIFT><SUPER>8']"

  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<SUPER>1']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<SUPER>2']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<SUPER>3']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<SUPER>4']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-5 "['<SUPER>5']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-6 "['<SUPER>6']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-7 "['<SUPER>7']"
  gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-8 "['<SUPER>8']"

  gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"

  gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true

  gsettings set org.gnome.system.location enabled true

  # TODO: validate app names
  gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'chrome.desktop', 'spotify.desktop', 'steam.desktop', 'com.slack.Slack.desktop', 'net.cozic.joplin_desktop.desktop', 'code.desktop', 'console.desktop']"

  # TODO: extension settings
fi

# 13. Enable systemd services
for i in ${systemd_services_root[@]}
do
	sudo systemctl enable $i
done

for i in ${systemd_services_user[@]}
do
	systemctl enable --user $i
done

# 14. Create Snapshot
sudo snapper -c root create --description "Post Arch Post-Install Tasks"

# Done
echo -e "\nArch Post-Install Tasks Complete!\n"

echo -n "Restarting in "
for i in {5..1}
do
  echo -n "$i..."
  sleep 1
done

systemctl reboot
