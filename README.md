# Desktop dotfiles

CachyOS · Hyprland 0.56 · Noctalia 5 · Kitty · Dolphin · Zen · LazyVim.
Requires Python 3.11+, Node.js and the desktop apps installed.

```bash
python3 install.py --check
python3 install.py
# Inside your Hyprland session:
bash scripts/apply-theme.sh
```

Existing configs are backed up; GUI overrides are reset to the saved preferences.
Restore with `python3 install.py --restore /path/to/BACKUP`.

Super+Ctrl+M toggles the portrait display; disconnects fall back automatically.
Adjust `.config/hypr/config/monitors.lua` for your displays.
Restart Zen after changing Noctalia’s palette.
External-monitor brightness: `bash scripts/setup-brightness.sh` (sudo required).
Optional greeter/timezone templates: `system/`.
