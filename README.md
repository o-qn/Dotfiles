# Desktop dotfiles

Umrbriel (main window manager) · Noctalia 5 · Niri 26 · Hyprland 0.56 · Kitty · Fish · Nemo · Gwenview · Easy Effects · Zen · LazyVim.
Requires Python 3.11+, Node.js, and the desktop apps installed.

```bash
# Inside your Niri or Hyprland session:
bash scripts/apply-theme.sh
```

Desktop configs are symlinked to `~/.config/` and `~/.local/`.

- **Compositor & Window Management**: **Niri** is the primary scrollable tiling compositor (`.config/niri/`), hooked with Noctalia desktop shell and color themes. Hyprland configuration (`.config/hypr/`) is maintained as a fallback session.
- **Monitors & Displays**: Super+A → Displays controls either monitor; Super+Ctrl+M toggles the portrait display; disconnects fall back automatically and reconnects restore the last portrait workspace. Adjust `.config/niri/config.kdl` (or `.config/hypr/config/monitors.lua`) for your displays.
- **Shell & Prompt**: Fish shell (`.config/fish/`) configured with Fisher, Tide prompt, Fastfetch, and Starship.
- **Theming**: Restart Zen after changing Noctalia’s palette.
- **External-monitor brightness**: `bash scripts/setup-brightness.sh` (sudo required).
- **Bongo Cat keyboard mode**: `bash scripts/setup-noctalia-plugins.sh` (sudo required).
- **Scheduled system snapshots**: `bash scripts/setup-snapper.sh` (sudo required).
- **Optional greeter/timezone templates**: `system/` (includes Noctalia Greeter and greetd configs).
