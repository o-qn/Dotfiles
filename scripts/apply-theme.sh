#!/usr/bin/env bash
set -euo pipefail
# Run explicitly inside your Hyprland session after installing the dotfiles.
noctalia msg config-reload
noctalia msg templates-apply
xdg-mime default org.kde.dolphin.desktop inode/directory
kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme noctalia
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
fi
printf 'Noctalia templates applied. Restart Zen; reopen Qt apps if colors do not refresh.\n'
