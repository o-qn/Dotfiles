# Desktop dotfiles

Umbriel (main window manager) · Noctalia 5 · Niri 26 · Hyprland 0.56 · Kitty · Fish · Dolphin · Gwenview · Zen · LazyVim.
Requires Python 3.11+, Node.js, and the desktop apps installed.

```bash
# Inside your Umbriel, Niri, or Hyprland session:
bash scripts/apply-theme.sh
```

Desktop configs are deployed to `~/.config/` and `~/.local/` via `python3 install.py` (copy mode) or `python3 install.py --symlink` (symlink mode).

- **Compositor & Window Management**: **Umbriel** (`.config/umbriel/`) is the main session; **Niri** (`.config/niri/`) and **Hyprland** (`.config/hypr/`) are maintained as standalone alternates sharing helper commands in `.local/bin/`.
- **Monitors & Displays**: `Super+T` (Umbriel/Niri) or `Super+A` (Hyprland) → Displays controls either monitor; `Super+Ctrl+M` toggles the portrait display. Adjust `.config/umbriel/config.toml`, `.config/niri/config.kdl`, or `.config/hypr/config/monitors.lua` for your displays.
- **Shell & Prompt**: Fish shell (`.config/fish/`) configured with Fisher, Tide prompt, and Fastfetch.
- **Theming**: `scripts/apply-theme.sh` wires Dolphin, Gwenview, EasyEffects, and Noctalia's palette.
- **External-monitor brightness**: `bash scripts/setup-brightness.sh` (sudo required).
- **Bongo Cat keyboard mode**: `bash scripts/setup-noctalia-plugins.sh` (sudo required).
- **Scheduled system snapshots**: `bash scripts/setup-snapper.sh` (sudo required).
- **Optional greeter/timezone templates**: `system/` (includes Noctalia Greeter and greetd configs).
