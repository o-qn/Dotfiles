#!/usr/bin/env bash
set -euo pipefail
# Run explicitly inside your Umbriel, Niri, or Hyprland session after installing the dotfiles.
noctalia msg config-reload
noctalia msg templates-apply

# Default file manager: Luciole (fallback to Dolphin if Luciole is unavailable)
if command -v luciole >/dev/null; then
    xdg-mime default dev.noctalia.luciole.desktop inode/directory
elif command -v dolphin >/dev/null; then
    xdg-mime default org.kde.dolphin.desktop inode/directory
fi

if command -v kwriteconfig6 >/dev/null; then
    if command -v dolphin >/dev/null; then
        kwriteconfig6 --file dolphinrc --group UiSettings --key ColorScheme noctalia
    fi
    if command -v easyeffects >/dev/null; then
        kwriteconfig6 --file easyeffectsrc --group UiSettings --key ColorScheme noctalia
    fi
    kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Breeze
    kwriteconfig6 --file kdeglobals --group Icons --key Theme Papirus-Dark
    kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
    kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
fi

qt6ct_conf="${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/qt6ct.conf"
if [[ -f "$qt6ct_conf" ]] && command -v python3 >/dev/null; then
    python3 -c '
import configparser, pathlib, sys
path = pathlib.Path(sys.argv[1])
cfg = configparser.RawConfigParser()
cfg.optionxform = str
cfg.read(path)
if not cfg.has_section("Appearance"):
    cfg.add_section("Appearance")
cfg.set("Appearance", "color_scheme_path", sys.argv[2])
with path.open("w") as f:
    cfg.write(f, space_around_delimiters=False)
' "$qt6ct_conf" "${XDG_CONFIG_HOME:-$HOME/.config}/qt6ct/colors/noctalia.conf"
fi

# Default image viewer: Loupe (GTK4/libadwaita, styled via Noctalia gtk4 template)
if command -v loupe >/dev/null; then
    IFS=: read -ra data_dirs <<< "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for dir in "${data_dirs[@]}"; do
        desktop_file="$dir/applications/org.gnome.Loupe.desktop"
        if [[ -f "$desktop_file" ]]; then
            while IFS= read -r image_mime; do
                [[ -n "$image_mime" ]] && xdg-mime default org.gnome.Loupe.desktop "$image_mime"
            done < <(sed -n 's/^MimeType=//p' "$desktop_file" | tr ';' '\n' | grep '^image/' || true)
            break
        fi
    done
    for extra_mime in image/heif image/x-ico image/x-webp; do
        xdg-mime default org.gnome.Loupe.desktop "$extra_mime"
    done
fi

if command -v gsettings >/dev/null; then
    gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty 2>/dev/null || true
fi
for gtk_ini in "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-3.0/settings.ini" "${XDG_CONFIG_HOME:-$HOME/.config}/gtk-4.0/settings.ini"; do
    if [[ -f "$gtk_ini" ]]; then
        sed -i 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=Bibata-Modern-Ice/' "$gtk_ini"
    fi
done
printf 'Noctalia templates applied (Luciole, Loupe/GTK4, Qt, Zen). Restart Zen; reopen apps if colors do not refresh.\n'
