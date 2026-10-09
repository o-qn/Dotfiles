# Desktop dotfiles

CachyOS · Hyprland 0.56 · Noctalia 5 · Kitty · Dolphin · Gwenview · Easy Effects · Zen · LazyVim.
Requires Python 3.11+, Node.js and the desktop apps installed.

```bash
python3 install.py --check
python3 install.py
# Inside your Hyprland session:
bash scripts/apply-theme.sh
```

Existing configs are backed up; GUI overrides are reset to the saved preferences.
Restore with `python3 install.py --restore /path/to/BACKUP`.

Super+Ctrl+M toggles the portrait display; disconnects fall back automatically and reconnects restore the last portrait workspace.
Adjust `.config/hypr/config/monitors.lua` for your displays.
Restart Zen after changing Noctalia’s palette.
External-monitor brightness: `bash scripts/setup-brightness.sh` (sudo required).
Bongo Cat keyboard mode: `bash scripts/setup-noctalia-plugins.sh` (sudo required).
Scheduled system snapshots: `bash scripts/setup-snapper.sh` (sudo required).
Optional greeter/timezone templates: `system/`.
