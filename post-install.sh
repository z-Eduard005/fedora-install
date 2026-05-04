#!/bin/bash
RAW_GITHUB="https://raw.githubusercontent.com/z-Eduard005/fedora-install/main"
MC_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/fedora-mc-installer/main/mc-installer.sh)"'
OBS_HOTKEYS_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-obs-hotkeys/main/install.sh)"'
VICINAE_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/z-Eduard005/gnome-vicinae-installer/main/install.sh)"'
OMZ_INSTALLER='sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
YTM_DOWNLOAD_URL="https://api.github.com/repos/pear-devs/pear-desktop/releases/latest"
RPM_FUSION_CMD="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
EXT_CLI="$HOME/.local/bin/gnome-extensions-cli"
WALLPAPERS_DIR="$HOME/.local/share/backgrounds"
WALLPAPERS_URL="$RAW_GITHUB/wallpapers"
DNF_CONF="/etc/dnf/dnf.conf"
SCRIPT_DATA_DIR="$HOME/.local/share/z-Eduard005-fedora-post-install"
LIBREOFFICE_USER_DIR="$HOME/.config/libreoffice/4/user"

REMOVE_PKGS=(gnome-tour baobab malcontent-control yelp)
DNF_PKGS=(python3-pip zsh gnome-tweaks steam)
CODEC_PKGS=(x264 obs-studio-plugin-x264)
FLATHUB_PKGS=(com.mattjakeman.ExtensionManager com.usebottles.bottles)
FLATPAK_PKGS=(com.github.neithern.g4music)

success() { printf "\033[1;32m%s\033[0m" "$1"; }
err() { printf "\033[1;31m%s\033[0m" "$1"; }
warn() { printf "\033[1;33m%s\033[0m" "$1"; }
info() { printf "\033[1;34m%s\033[0m" "$1"; }
throw_err() { echo "$(err "$1")"; exit 1; }

set_dnf_conf_option() {
  local key="$1"
  local value="$2"
  if grep -q "^${key}=" "$DNF_CONF"; then
    sudo sed -i "s|^${key}=.*|${key}=${value}|" "$DNF_CONF"
  else
    echo "${key}=${value}" | sudo tee -a "$DNF_CONF" >/dev/null
  fi
}

log_step() {
  echo "$(info "$step")"
}

save_step() {
  echo "$step" >> "$STATE_FILE"
}

run_the_step() {
  grep -qxF "$step" "$STATE_FILE" && {
    echo "$(info "$(echo "$step" | sed 's/]:.*$/]:/') skipped")"
    return 1
  }
  log_step
}

[ "$EUID" -eq 0 ] && echo "$(err 'Do not run this script with "sudo"!')" >&2; exit 1

sudo -v || exit 1
while true; do
  sudo -n true
  sleep 240
  kill -0 "$$" || exit
done 2>/dev/null &

mkdir -p "$SCRIPT_DATA_DIR"
STATE_FILE="$SCRIPT_DATA_DIR/state"
[ ! -f "$STATE_FILE" ] && touch "$STATE_FILE"

step="[1|13]: Configuring system package manager"
log_step
set_dnf_conf_option "max_parallel_downloads" "15"
set_dnf_conf_option "fastestmirror" "True"
set_dnf_conf_option "installonly_limit" "2"

step="[2|13]: Updating the system"
log_step
sudo dnf upgrade -y --skip-unavailable && sudo flatpak update || {
  sudo dnf install -y tor
  sudo systemctl start tor
  sudo all_proxy="socks5://127.0.0.1:9050" dnf upgrade --refresh -y --skip-unavailable
  sudo all_proxy="socks5://127.0.0.1:9050" flatpak update
}
fwupdmgr refresh >/dev/null 2>&1 && fwupdmgr update >/dev/null 2>&1

step="[3|13]: Enabling the RPM Fusion repository (for more packages)"
run_the_step && {
  sudo dnf install -y "$RPM_FUSION_CMD" || throw_err "RPM Fusion enabling error"
} && save_step

step="[4|13]: Installing essential codecs"
run_the_step && {
  sudo dnf install -y "${CODEC_PKGS[@]}" --allowerasing
} && save_step

step="[5|13]: Installing essential programs"
run_the_step && {
  sudo dnf install -y "${DNF_PKGS[@]}"
  sudo flatpak install -y flathub "${FLATHUB_PKGS[@]}"
  sudo flatpak install -y fedora "${FLATPAK_PKGS[@]}"
  pip3 install $(basename $EXT_CLI)
  eval "$OMZ_INSTALLER"
} && save_step

step="[6|13]: Removing unnecessary programs"
run_the_step && {
  sudo dnf remove -y "${REMOVE_PKGS[@]}"
} && save_step

step="[7|13]: Make the system start faster"
run_the_step && {
  sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=3/' /etc/default/grub
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
} && save_step

step="[8|13]: Tweaking terminal"
run_the_step && {
  if ! grep -q 'source ~/.bashrc' "$HOME/.zshrc"; then
    echo -e "\n# Source the .bashrc config\n[ -f ~/.bashrc ] && source ~/.bashrc" >> "$HOME/.zshrc"
  fi
  if grep -q ' . /etc/bashrc' "$HOME/.bashrc"; then
    sed -i 's| . /etc/bashrc|#. /etc/bashrc|' "$HOME/.bashrc"
  fi
  [ "$SHELL" != "$(which zsh)" ] && chsh -s "$(which zsh)"
} && save_step

step="[9|13]: Changing default music app"
run_the_step && {
  xdg-mime default com.github.neithern.g4music.desktop audio/mpeg audio/flac audio/x-wav audio/ogg
} && save_step

step="[10|13]: Tweaking system settings"
run_the_step && {
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

  mkdir -p "$LIBREOFFICE_USER_DIR"
  cat > "$LIBREOFFICE_USER_DIR/registrymodifications.xcu" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Writer']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Calc']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Impress']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.UI.ToolbarMode/Applications/org.openoffice.Office.UI.ToolbarMode:Application['Draw']"><prop oor:name="Active" oor:op="fuse"><value>notebookbar.ui</value></prop></item>
<item oor:path="/org.openoffice.Office.Common/Misc"><prop oor:name="SymbolStyle" oor:op="fuse"><value>sukapura_svg</value></prop></item>
</oor:items>
EOF
} && save_step

step="[11|13]: Installing essential gnome extensions"
run_the_step && {
  $EXT_CLI install appindicatorsupport@rgcjonas.gmail.com quick-lang-switch@ankostis.gmail.com blur-my-shell@aunetx just-perfection-desktop@just-perfection Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com
  $EXT_CLI disable background-logo@fedorahosted.org Vitals@CoreCoding.com hidetopbar@mathieu.bidon.ca rounded-window-corners@fxgn color-picker@tuberry dash-to-panel@jderose9.github.com dash-to-dock@micxgx.gmail.com gtk4-ding@smedius.gitlab.com
} && save_step

SELECTED_LOOK=$(zenity --list --radiolist \
  --title="Desktop Look" \
  --text="Choose the look of your desktop:" \
  --column="" --column="Look" \
  FALSE "macos" FALSE "windows" TRUE "linux" \
  --width=480 --height=480)

[ -z "$SELECTED_LOOK" ] && { throw_err "Cancelled"; }

PROGRAMS=$(zenity --list --checklist \
  --title="Programs to install" \
  --text="Select programs then click OK:" \
  --column="Install" --column="ID" --column="Description" \
  --separator=" " \
  FALSE "color-picker"    "Color Picker (GNOME Extension)" \
  FALSE "rounded-corners" "Rounded Window Corners (GNOME Extension)" \
  FALSE "hidetopbar"      "Hide Top Bar (GNOME Extension)" \
  FALSE "vitals"          "Vitals - system monitor" \
  FALSE "minecraft"       "Minecraft (FREE VERSION)" \
  FALSE "youtube-music"   "YouTube Music App" \
  FALSE "vicinae"         "Vicinae - launcher & clipboard manager" \
  FALSE "obs-hotkeys"     "Fix OBS recording hotkeys (you want this if you will record with obs)" \
  --width=960 --height=540)

[ $? -ne 0 ] && { throw_err "Cancelled"; }

selected() { echo "$PROGRAMS" | grep -qw "$1"; }

step="[12|13]: Setting up look of your desktop"; log_step
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
  "linux")
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

step="[13|13]: Installing recommended programs"; log_step
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
  eval "$MC_INSTALLER" || throw_err "Minecraft installation failed. Try later by running this program again"
fi

if selected "youtube-music"; then
  if rpm -qa | grep -q youtube-music; then
    echo "$(warn "YouTube Music App is already installed")"
  else
    ytm_release_url=$(echo "$YTM_DOWNLOAD_URL" | sed 's/api\.//; s/repos\///')
    echo "Installing YouTube Music App from \"$ytm_release_url\"..."
    curl -s "$YTM_DOWNLOAD_URL" | grep browser_download_url | grep x86_64.rpm | cut -d '"' -f 4 | xargs curl -L -o "$HOME/Downloads/youtube-music.rpm"
    sudo dnf install -y "$HOME/Downloads/youtube-music.rpm"
  fi
fi

if selected "vicinae"; then
  eval "$VICINAE_INSTALLER" || throw_err "Vicinae installation failed. Try later by running this program again"
fi

if selected "obs-hotkeys"; then
  eval "$OBS_HOTKEYS_INSTALLER" || throw_err "OBS Hotkeys installation failed. Try later by running this program again"
fi

zenity --info \
  --title="Setup Complete!" \
  --text="🎉 Your Fedora installation is ready to use! Have fun :)\n\nYou can install any app in the default Software App or from browser using .rpm (x86_64), .AppImage or .snap file formats.\n\nWhat was done:\n• Package manager optimized\n• System updated\n• RPM Fusion enabled\n• Essential codecs installed\n• Boot time reduced\n• Terminal utilities installed (zsh, oh-my-zsh)\n• Default music app changed\n• Essential programs installed\n• Unnecessary programs removed\n• System settings tweaked\n• GNOME extensions installed\n• Desktop look configured\n• Selected programs installed\n\n⚠️ Your system needs to reboot for all changes to take effect." \
  --width=960 --height=540

zenity --question \
  --title="Reboot" \
  --text="Do you want to reboot now?" \
  --ok-label="Reboot now" \
  --cancel-label="Later" \
  --width=480 --height=480 && systemctl reboot
