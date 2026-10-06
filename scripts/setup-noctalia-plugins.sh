#!/usr/bin/env bash
set -euo pipefail
# Run as your desktop user; permission is limited to the Apex 7 TKL keyboard.
if (( EUID == 0 )); then
  printf 'Run this as your desktop user, without sudo in front of bash.\n' >&2
  exit 1
fi
plugin_config="${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/desktop-plugins.toml"
if [[ ! -f "$plugin_config" ]]; then
  printf 'Missing %s; apply these dotfiles first.\n' "$plugin_config" >&2
  exit 1
fi
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sudo pacman -S --needed evtest socat
sudo install -Dm644 "$script_dir/../system/udev/70-noctalia-bongocat.rules" /etc/udev/rules.d/70-noctalia-bongocat.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=input --action=add
sudo udevadm settle
shopt -s nullglob
keyboard_devices=(/dev/input/by-id/usb-SteelSeries_SteelSeries_Apex_7_TKL*-event-kbd)
if (( ${#keyboard_devices[@]} == 0 )); then
  printf 'Apex 7 TKL keyboard was not found. Reconnect it and run this script again.\n' >&2
  exit 1
fi
for device in "${keyboard_devices[@]}"; do
  if [[ ! -r "$device" ]]; then
    printf 'Keyboard permission is not active yet. Log out and back in, then run this script again.\n' >&2
    exit 1
  fi
done
python3 - "$plugin_config" <<'PY'
from pathlib import Path
import re,sys
p=Path(sys.argv[1])
text=p.read_text()
pattern=r'(\[widget\.cat\]\n[^\[]*?\ninput_devices\s*=\s*)\[[^\n]*\]'
text,count=re.subn(pattern, r'\g<1>["/dev/input/by-id/usb-SteelSeries_SteelSeries_Apex_7_TKL*-event-kbd"]', text, count=1)
if count != 1:
    raise SystemExit('Could not find Bongo Cat input_devices; open its widget settings to select your keyboard.')
p.write_text(text)
PY
noctalia config validate
noctalia msg config-reload
printf 'Bongo Cat keyboard tapping enabled; video slideshow frame sync is available.\n'
