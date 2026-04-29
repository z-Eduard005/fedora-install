#!/bin/bash
EXT_CLI="$HOME/.local/bin/gnome-extensions-cli"
WALLPAPERS_DIR="$HOME/.local/share/backgrounds"
RAW_GITHUB="https://raw.githubusercontent.com/z-Eduard005/fedora-install/main"
WALLPAPERS_URL="$RAW_GITHUB/wallpapers"
DNF_CONF="/etc/dnf/dnf.conf"
MC_INSTALL_CMD='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/fedora-mc-installer/main/mc-installer.sh)"'
AUTOSTART_DIR="$HOME/.config/autostart"
VICINAE_ENTRY_DIR="/usr/local/share/applications"
APP_DIR="$HOME/.local/share/z-Eduard005-fedora-post-install"
OBS_HOTKEYS_DIR="$HOME/Programs/obs-hotkeys"

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }
info() { printf "\033[1;34m%s\033[0m" "$1"; }

if [ "$EUID" -eq 0 ]; then
  echo "$(err 'Do not run this script as root!')" >&2
  exit 1
fi

sudo -v || exit 1
while true; do
  sudo -n true
  sleep 240
  kill -0 "$$" || exit
done 2>/dev/null &

mkdir -p "$APP_DIR"
STATE_FILE="$APP_DIR/state"
if [ ! -f "$STATE_FILE" ]; then
  touch "$STATE_FILE"
fi

step="[1|13]: Make the package manager faster"
echo "$(info "$step")"
if ! grep -qxF 'max_parallel_downloads=20' "$DNF_CONF"; then
  echo 'max_parallel_downloads=20' | sudo tee -a "$DNF_CONF" >/dev/null
fi
if ! grep -qxF 'fastestmirror=True' "$DNF_CONF"; then
  echo 'fastestmirror=True' | sudo tee -a "$DNF_CONF" >/dev/null
fi
if ! grep -qxF 'installonly_limit=2' "$DNF_CONF"; then
  echo 'installonly_limit=2' | sudo tee -a "$DNF_CONF" >/dev/null
fi

step="[2|13]: Updating the system"
echo "$(info "$step")"
sudo dnf upgrade -y --skip-unavailable && sudo flatpak update || {
  sudo dnf install -y tor
  sudo systemctl start tor
  sudo all_proxy="socks5://127.0.0.1:9050" dnf upgrade --refresh -y --skip-unavailable
  sudo all_proxy="socks5://127.0.0.1:9050" flatpak update
}

step="[3|13]: Enable the RPM Fusion repository (for more packages)"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  echo "$step" >> "$STATE_FILE"
fi

step="[4|13]: Installing essential codecs"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  sudo dnf install -y x264 obs-studio-plugin-x264 --allowerasing
  echo "$step" >> "$STATE_FILE"
fi

step="[5|13]: Make the system start faster"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  echo "$step" >> "$STATE_FILE"
fi

step="[6|13]: Installing Terminal utilities"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  sudo dnf install -y yad python3-pip zsh
  pip3 install gnome-extensions-cli
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  if ! grep -q 'source ~/.bashrc' "$HOME/.zshrc"; then
    echo -e "\n# Source the .bashrc config\n[ -f ~/.bashrc ] && source ~/.bashrc" >> "$HOME/.zshrc"
  fi
  if grep -q ' . /etc/bashrc' "$HOME/.bashrc"; then
    sed -i 's| . /etc/bashrc|#. /etc/bashrc|' "$HOME/.bashrc"
  fi
  chsh -s $(which zsh)
  echo "$step" >> "$STATE_FILE"
fi

step="[7|13]: Changing default music app"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  sudo flatpak install -y fedora com.github.neithern.g4music
  xdg-mime default com.github.neithern.g4music.desktop audio/mpeg audio/flac audio/x-wav audio/ogg
  echo "$step" >> "$STATE_FILE"
fi

step="[8|13]: Installing essential programs"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  sudo dnf install -y gnome-tweaks steam
  sudo flatpak install -y flathub com.mattjakeman.ExtensionManager com.usebottles.bottles
  echo "$step" >> "$STATE_FILE"
fi

step="[9|13]: Removing unnecessary programs"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  sudo dnf remove -y gnome-tour baobab malcontent-control yelp
  echo "$step" >> "$STATE_FILE"
fi

step="[10|13]: Tweaking system settings a bit"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  powerprofilesctl set performance
  gsettings set org.gnome.desktop.interface enable-hot-corners false
  gsettings set org.gnome.shell.app-switcher current-workspace-only true
  gsettings set org.gnome.mutter dynamic-workspaces false
  gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
  gsettings set org.gnome.desktop.input-sources per-window true
  gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
  gsettings set org.gnome.desktop.wm.preferences resize-with-right-button true
  gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Shift><Control><Alt>space']"
  gsettings set org.gnome.desktop.wm.keybindings close "['<Alt>w']"
  gsettings set org.gnome.shell favorite-apps "['org.gnome.Ptyxis.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Settings.desktop', 'com.mattjakeman.ExtensionManager.desktop', 'org.gnome.Software.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.SystemMonitor.desktop', 'org.mozilla.firefox.desktop', 'steam.desktop']"
  if ! gsettings get org.gnome.desktop.input-sources xkb-options | grep -q "grp:caps_toggle"; then
    gsettings set org.gnome.desktop.input-sources xkb-options "['grp:caps_toggle','lv3:ralt_switch']"
  fi
  echo "$step" >> "$STATE_FILE"
fi

step="[11|13]: Installing essential gnome extensions"
if ! grep -qx "$step" "$STATE_FILE"; then
  echo "$(info "$step")"
  $EXT_CLI install appindicatorsupport@rgcjonas.gmail.com quick-lang-switch@ankostis.gmail.com blur-my-shell@aunetx just-perfection-desktop@just-perfection Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com
  $EXT_CLI disable background-logo@fedorahosted.org Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com
  echo "$step" >> "$STATE_FILE"
fi

ID=$$
yad --notebook --key=$ID \
  --title="Fedora Setup" \
  --button="Start:0" \
  --tab="Desktop Look" \
  --tab="Programs" \
  --width=500 --height=400 &
NOTEBOOK_PID=$!

SELECTED_LOOK=$(yad --plug=$ID --tabnum=1 --list --radiolist \
  --column="" --column="Look" \
  TRUE  "macos" \
  FALSE "windows" \
  FALSE "nothing" \
  --print-column=2)

PROGRAMS=$(yad --plug=$ID --tabnum=2 --list --checklist \
  --column="Install" --column="ID" --column="Description" \
  --print-column=2 --separator=" " \
  FALSE "color-picker"    "Color Picker (GNOME Extension)" \
  FALSE "rounded-corners" "Rounded Window Corners (GNOME Extension)" \
  FALSE "hidetopbar"      "Hide Top Bar (GNOME Extension)" \
  FALSE "vitals"          "Vitals - system monitor (GNOME Extension)" \
  FALSE "minecraft"       "Minecraft (FREE VERSION)" \
  FALSE "youtube-music"   "YouTube Music App" \
  FALSE "vicinae"         "Vicinae - launcher & clipboard manager" \
  FALSE "obs-hotkeys"     "Fix OBS recording hotkeys")

wait $NOTEBOOK_PID || { echo "$(err "Cancelled.")"; exit 1; }

SELECTED_LOOK=$(echo "$SELECTED_LOOK" | tr -d '|[:space:]')
selected() { echo "$PROGRAMS" | grep -qw "$1"; }

echo "$(info "[12|13]: Setting up look of your desktop")"
case "$SELECTED_LOOK" in
  "windows")
    WALLPAPER_NAME="windows.jpg"
    $EXT_CLI install gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
    curl -fsSL "$RAW_GITHUB/dash-to-panel.conf" | dconf load /org/gnome/shell/extensions/dash-to-panel/
    $EXT_CLI enable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
    $EXT_CLI disable dash-to-dock@micxgx.gmail.com hidetopbar@mathieu.bidon.ca
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    ;;
  "macos")
    WALLPAPER_NAME="macos.png"
    $EXT_CLI install dash-to-dock@micxgx.gmail.com
    $EXT_CLI enable dash-to-dock@micxgx.gmail.com
    $EXT_CLI disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    ;;
  *)
    WALLPAPER_NAME="linux.jpg"
    $EXT_CLI disable gtk4-ding@smedius.gitlab.com dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
    ;;
esac

mkdir -p "$WALLPAPERS_DIR"
if [ ! -f "$WALLPAPERS_DIR/$WALLPAPER_NAME" ]; then
  curl -fsSL "$WALLPAPERS_URL/$WALLPAPER_NAME" -o "$WALLPAPERS_DIR/$WALLPAPER_NAME"
fi

WALLPAPER="file://$WALLPAPERS_DIR/$WALLPAPER_NAME"
gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER"
gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER"

echo "$(info "[13|13]: Installing recommended programs")"
if selected "color-picker"; then
  $EXT_CLI install color-picker@tuberry
  $EXT_CLI enable color-picker@tuberry
fi
if selected "rounded-corners"; then
  $EXT_CLI install rounded-window-corners@fxgn
  $EXT_CLI enable rounded-window-corners@fxgn
fi
if selected "hidetopbar"; then
  $EXT_CLI install hidetopbar@mathieu.bidon.ca
  $EXT_CLI enable hidetopbar@mathieu.bidon.ca
fi
if selected "vitals"; then
  $EXT_CLI install Vitals@CoreCoding.com
  $EXT_CLI enable Vitals@CoreCoding.com
fi
if selected "minecraft"; then
  if ! eval "$MC_INSTALL_CMD"; then
    echo "$(err "Minecraft installation failed. Try later by running this script:")"
    echo "$(info "$MC_INSTALL_CMD")"
  fi
fi
if selected "youtube-music"; then
  if rpm -qa | grep -q youtube-music; then
    echo "$(warn "YouTube Music App is already installed")"
  else
    curl -s https://api.github.com/repos/pear-devs/pear-desktop/releases/latest | grep browser_download_url | grep x86_64.rpm | cut -d '"' -f 4 | xargs curl -L -o "$HOME/Downloads/youtube-music.rpm"
    sudo dnf install -y "$HOME/Downloads/youtube-music.rpm"
  fi
fi
if selected "vicinae"; then
  if command -v vicinae &>/dev/null; then
    curl -fsSL https://vicinae.com/install.sh | bash
    echo "$(warn "Vicinae is already installed")"
  else
    $EXT_CLI install vicinae@dagimg-dot
    curl -fsSL https://vicinae.com/install.sh | bash && systemctl --user enable vicinae --now
    mkdir -p "$AUTOSTART_DIR"
    cp "$VICINAE_ENTRY_DIR/vicinae.desktop" "$AUTOSTART_DIR"

    existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    new=$(echo "$existing" | sed "s|]|, '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/']|")
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/ name 'Vicinae Toggle'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/ command 'vicinae toggle'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-toggle/ binding '<Alt>space'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/ name 'Vicinae Clipboard'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/ command 'vicinae deeplink vicinae://launch/clipboard/history'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/vicinae-clipboard/ binding '<Alt>v'

    echo "$(success "Vicinae installed. To use it, just press <Alt+Space>")"
    echo "$(success "And for using clipboard manager press <Alt+V>")"
  fi
fi

if selected "obs-hotkeys"; then
  if [ -d "$OBS_HOTKEYS_DIR" ]; then
    echo "$(warn "OBS hotkeys already installed")"
  else
    mkdir -p "$OBS_HOTKEYS_DIR"
    for f in package.json toggle-pause.js toggle-record.js; do curl -fsSL "$RAW_GITHUB/obs-hotkeys/$f" -o "$OBS_HOTKEYS_DIR/$f"; done
    (cd "$OBS_HOTKEYS_DIR" && npm install)

    existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    new=$(echo "$existing" | sed "s|]|, '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-pause/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-record/']|")
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new"

    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-pause/ name 'OBS Toggle Pause'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-pause/ command "node $OBS_HOTKEYS_DIR/toggle-pause.js"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-pause/ binding '<Control><Alt>BackSpace'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-record/ name 'OBS Toggle Record'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-record/ command "node $OBS_HOTKEYS_DIR/toggle-record.js"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/obs-record/ binding '<Control><Shift><Alt>BackSpace'

    echo "$(success "OBS hotkeys set. <Ctrl+Alt+Backspace> to toogle pause, <Ctrl+Shift+Alt+Backspace> to toggle recording")"
  fi
fi

yad --title="Setup Complete!" \
  --text="🎉 <b>Your Fedora installation is ready to use! Have fun :)</b>\n\nYou can install any app in the default Software App or from browser using <b>.rpm</b>, <b>.AppImage</b> or <b>.snap</b> file formats.\n\n<b>What was done:</b>\n• Package manager optimized\n• System updated\n• RPM Fusion enabled\n• Essential codecs installed\n• Boot time reduced\n• Terminal utilities installed (zsh, oh-my-zsh)\n• Default music app changed\n• Essential programs installed\n• Unnecessary programs removed\n• System settings tweaked\n• GNOME extensions installed\n• Desktop look configured\n• Selected programs installed\n\n⚠️ <b>Your system needs to reboot for all changes to take effect.</b>" \
  --button="Reboot now:0" \
  --button="Later:1" \
  --width=500 --height=400 &
REBOOT_PID=$!

wait $REBOOT_PID && systemctl reboot