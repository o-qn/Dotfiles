#!/usr/bin/env bash
set -euo pipefail
# Run explicitly inside your Hyprland session after installing the dotfiles.
noctalia msg config-reload
noctalia msg templates-apply
xdg-mime default com.system76.CosmicFiles.desktop inode/directory
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
fi
printf 'Tokyo Night templates applied. Reopen COSMIC Files to refresh its colors.\n'
