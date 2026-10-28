#!/usr/bin/env bash
set -euo pipefail
# Run explicitly inside your Hyprland session after installing the dotfiles.
noctalia msg config-reload
noctalia msg templates-apply
xdg-mime default nemo.desktop inode/directory
if command -v kwriteconfig6 >/dev/null; then
    if command -v easyeffects >/dev/null; then
        kwriteconfig6 --file easyeffectsrc --group UiSettings --key ColorScheme noctalia
    fi
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
    kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
    if command -v gwenview >/dev/null; then
        kwriteconfig6 --file gwenviewrc --group UiSettings --key ColorScheme noctalia
        kwriteconfig6 --file gwenviewrc --group FullScreen --key FullScreenColorScheme "${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes/noctalia.colors"
    fi
fi
# KDE image viewer uses the same generated palette in normal and fullscreen UI.
if command -v gwenview >/dev/null; then
    IFS=: read -ra data_dirs <<< "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for dir in "${data_dirs[@]}"; do
        desktop_file="$dir/applications/org.kde.gwenview.desktop"
        if [[ -f "$desktop_file" ]]; then
            while IFS= read -r image_mime; do
                [[ -n "$image_mime" ]] && xdg-mime default org.kde.gwenview.desktop "$image_mime"
            done < <(sed -n 's/^MimeType=//p' "$desktop_file" | tr ';' '\n' | grep '^image/' || true)
            break
        fi
    done
fi
if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
    gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty 2>/dev/null || true
fi
printf 'Noctalia templates applied. Restart Zen; reopen Qt apps if colors do not refresh.\n'
