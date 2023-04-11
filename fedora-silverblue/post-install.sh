#!/bin/bash

while getopts 'hd:' opt; do
  case "$opt" in
    d)
      arg="$OPTARG"
      if [[ "$arg" == "framework" ]]; then
        device="$arg"
      fi
      ;;

    ?|h)
      echo "Usage: $(basename $0) [-v] [-d device] [-p profile]"
      echo -e "-d <device>\t runs additional tasks based on the device (available devices: framework)"
      exit 1
      ;;
  esac
done

root=$(dirname $(realpath $0))

flatpak_apps=(
  app/org.mozilla.firefox/x86_64/stable
  com.discordapp.Discord
  com.getpostman.Postman
  com.github.marhkb.Pods
  com.github.tchx84.Flatseal
  com.google.Chrome
  com.mattjakeman.ExtensionManager
  com.slack.Slack
  com.spotify.Client
  com.usebottles.bottles
  com.valvesoftware.Steam
  com.valvesoftware.Steam.CompatibilityTool.Proton
  com.valvesoftware.Steam.Utility.gamescope
  com.visualstudio.code
  io.github.realmazharhussain.GdmSettings
  net.cozic.joplin_desktop
  org.gnome.World.PikaBackup
  org.gtk.Gtk3theme.adw-gtk3
  org.libreoffice.LibreOffice
  org.signal.Signal
  runtime/org.freedesktop.Platform.ffmpeg-full/x86_64/22.08
  us.zoom.Zoom
)

echo "Starting Fedora Silverblue Post-Install Tasks..."

# 1. Update base image
sudo rpm-ostree --apply-live update

# 2. Add starship COPR repo
sudo cp $root/assets/_copr_atim-starship.repo /etc/yum.repos.d/

# 3. Layer fish and starship
sudo rpm-ostree --apply-live install fish starship
sudo usermod -s $(command -v fish) $USER

# 4. Device
case $device in
  framework)
    # fixing brightness keys
    sudo rpm-ostree kargs --append="module_blacklist=hid_sensor_hub"

    # fixing screen freezes
    sudo rpm-ostree kargs --append="i915.enable_psr=0"
    ;;
esac

# 5. Replace fedora flatpak repo with flathub (https://www.reddit.com/r/Fedora/comments/z2kk88/fedora_silverblue_replace_the_fedora_flatpak_repo/)
sudo flatpak remote-modify --no-filter --enable flathub
flatpak install --noninteractive --reinstall flathub $(flatpak list --app-runtime=org.fedoraproject.Platform --columns=application | tail -n +1 )
sudo flatpak remote-delete fedora

# 6. Install flatpak apps
for app in ${flatpak_apps[@]}
do
	flatpak install --noninteractive $app
done

# 7. Copy config files
# shell
mkdir -p ~/.config/fish/
cp $root/assets/config.fish ~/.config/fish/
cp $root/assets/starship.toml ~/.config/

# podman
mkdir -p ~/.config/containers/
cp $root/assets/containers.conf ~/.config/containers/
cp $root/assets/registries.conf ~/.config/containers/

# AWS ECR helper config
mkdir ~/.docker
cp $root/assets/docker-config.json ~/.docker/config.json

# podman host script
mkdir -p ~/.local/bin/
install --mode 755 -T $root/assets/podman-host.sh ~/.local/bin/podman-host

# VS Code container config
mkdir -p ~/.var/app/com.visualstudio.code/config/Code/User/globalStorage/ms-vscode-remote.remote-containers/nameConfigs/
cp $root/assets/dev-toolbox.json ~/.var/app/com.visualstudio.code/config/Code/User/globalStorage/ms-vscode-remote.remote-containers/nameConfigs/

# 8. Add themes
mkdir -p ~/.local/share/themes/

tmp_dir=$(mktemp -d)
curl -L https://github.com/lassekongo83/adw-gtk3/releases/download/v4.5/adw-gtk3v4-5.tar.xz --output $tmp_dir/adw-gtk3v4-5.tar.xz
tar -xf $tmp_dir/adw-gtk3v4-5.tar.xz -C ~/.local/share/themes/
rm -rf $tmp_dir

# 9. Add fonts
mkdir -p ~/.local/share/fonts/

tmp_dir=$(mktemp -d)
curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/JetBrainsMono.zip --output $tmp_dir/JetBrainsMono.zip
unzip $tmp_dir/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono/
rm -rf $tmp_dir

# 10. hide built-in firefox
mkdir -p ~/.local/share/applications/
sed '2iHidden=true' /usr/share/applications/firefox.desktop > ~/.local/share/applications/firefox.desktop

# 11. set wayland vars for flatpak apps
# vs code
sed 's/@@ %F @@/--enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland @@ %F @@/g' /var/lib/flatpak/exports/share/applications/com.visualstudio.code.desktop > ~/.local/share/applications/com.visualstudio.code.desktop
sed 's/@@ %F @@/--enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland @@ %F @@/g' /var/lib/flatpak/exports/share/applications/com.visualstudio.code-url-handler.desktop > ~/.local/share/applications/com.visualstudio.code-url-handler.desktop

# slack
sed 's/@@u %U @@/--enable-features=UseOzonePlatform,WaylandWindowDecorations,WebRTCPipeWireCapturer --ozone-platform=wayland @@u %U @@/g' /var/lib/flatpak/exports/share/applications/com.slack.Slack.desktop > ~/.local/share/applications/com.slack.Slack.desktop

# postman
sed 's/@@u %U @@/--enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland @@u %U @@/g' /var/lib/flatpak/exports/share/applications/com.getpostman.Postman.desktop > ~/.local/share/applications/com.getpostman.Postman.desktop

# 12. create toolbox
podman build -t dev-toolbox -f $root/assets/Containerfile
toolbox create -i dev-toolbox dev

# 13. gnome settings
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

gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.mozilla.firefox.desktop', 'com.google.Chrome.desktop', 'com.spotify.Client.desktop', 'com.valvesoftware.Steam.desktop', 'com.slack.Slack.desktop', 'net.cozic.joplin_desktop.desktop', 'com.visualstudio.code.desktop', 'org.gnome.Terminal.desktop']"

# TODO: extension settings

# 13. Enable systemd services
systemctl --user enable --now podman.socket

# Done
echo -e "\nFedora Silverblue Post-Install Tasks Complete!\n"

echo -n "Restarting in "
for i in {5..1}
do
  echo -n "$i..."
  sleep 1
done

systemctl reboot
