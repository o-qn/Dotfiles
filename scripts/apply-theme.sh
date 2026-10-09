#!/usr/bin/env bash
set -euo pipefail
# Run explicitly inside your Hyprland session after installing the dotfiles.
noctalia msg config-reload
noctalia msg templates-apply
xdg-mime default org.kde.dolphin.desktop inode/directory
kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme noctalia
if command -v easyeffects >/dev/null; then
    kwriteconfig6 --file easyeffectsrc --group UiSettings --key ColorScheme noctalia
fi
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
# KDE image viewer uses the same generated palette in normal and fullscreen UI.
if command -v gwenview >/dev/null; then
    kwriteconfig6 --file gwenviewrc --group UiSettings --key ColorScheme noctalia
    kwriteconfig6 --file gwenviewrc --group FullScreen --key FullScreenColorScheme "${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/noctalia.colors"
    image_mimes=$(sed -n 's/^MimeType=//p' /usr/share/applications/org.kde.gwenview.desktop | tr ';' '\n' | rg '^image/')
    while IFS= read -r image_mime; do
        xdg-mime default org.kde.gwenview.desktop "$image_mime"
    done <<< "$image_mimes"
fi
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
fi
printf 'Noctalia templates applied. Restart Zen; reopen Qt apps if colors do not refresh.\n'
