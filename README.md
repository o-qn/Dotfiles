# Desktop dotfiles

Umbriel (main window manager) · Noctalia 5 · Niri 26 · Hyprland 0.56 · Kitty · Fish · Dolphin · Gwenview · Zen · LazyVim.
Requires Python 3.11+, Node.js, and the desktop apps installed.

```bash
# Validate configs offline in a temporary directory:
python3 install.py --check

# Inside your Umbriel, Niri, or Hyprland session:
bash scripts/apply-theme.sh
```

Desktop configs are deployed to `~/.config/` and `~/.local/` via `python3 install.py` (copy mode) or `python3 install.py --symlink` (symlink mode).

## Highlights

- **Compositor & Window Management**: **Umbriel** (`.config/umbriel/`) is the main session (1440p@200Hz primary + 1080p@144Hz portrait with full-width portrait scrolling, Workspace 1 pinned to Dwindle, Workspaces 2–10 Scrolling); **Niri** (`.config/niri/`) and **Hyprland** (`.config/hypr/`) are maintained as standalone alternates sharing `.local/bin/desktop-*` helpers.
- **Monitors, VRR & Zero-Reload Runtime State**:
  - `Super+T` (Umbriel/Niri) or `Super+A` (Hyprland) → Control Center (**Displays** & **Umbriel Controls** plugins).
  - `Super+Ctrl+M` safely toggles the portrait display (`desktop-displays toggle portrait`, guarding against disabling the last active monitor).
  - `Super+Shift+D` cycles VRR (`fullscreen` / `always` / `disabled`) dynamically via `umbriel-ctl` (`umbriel config set`, zero config reloads), persisting runtime VRR, HDR, SDR white, tearing, shader, and animation settings outside git in `~/.local/state/umbriel/state.json` (replayed on startup). Desktop defaults to `vrr = "fullscreen"` so NVIDIA stays on fixed refresh when idle.
  - `umbriel-watcher` listens to `umbriel subscribe windows` and automatically suspends persistent shaders (plus optional DND) during fullscreen games to maximize Direct Scanout without touching VRR.
- **Noctalia Umbriel Plugin** (`.local/share/noctalia/plugins/umbriel-layout/`):
  - Unified role-aware `layout` and `ws1` bar pills (`main` / `portrait`), an auto-hiding `status` pill for active submaps, live screencasts, and hidden scratchpads, and an event-driven dual-monitor Control Center panel (`panel.luau`).
- **Scratchpads & Modal Submaps (Umbriel)**:
  - **Scratchpads**: `Super+;` toggles a floating terminal (`term`), `Super+'` toggles the `quick` drawer, `Super+Shift+'` stashes/restores the focused window, `Super+Ctrl+'` cycles stashed windows.
  - **Window submap (`Super+Alt+W`)**: Arrows snap halves, `1–4` snap quarters, `0` clear region, `c` center, `p` pin, `m` maximize-to-edges, `t` / `[` / `]` tab controls, `s` swap active workspaces across monitors (`Esc`/`Enter`/`q` exits).
  - **Screencast submap (`Super+Alt+S`)**: `o` share output, `w` share window, `f` follow window, `m` follow output, `p` stop following, `x` clear (`Esc`/`Enter`/`q` exits).
- **Diagnostics & Shortcuts**: `Super+Shift+R` validates and reloads (`desktop-reload`), `Super+Ctrl+Q` runs live compositor/display pipeline diagnostics (`desktop-doctor`), `Super+F1` searches keybinds (`desktop-shortcuts`), and `Super+Shift+/` toggles Umbriel's built-in cheatsheet.
- **Shell, Prompt & Network**: Fish shell (`.config/fish/`) with Fisher, Tide prompt, Fastfetch, and `net-toggle` (`Super+U` / `net-tune` / `net-reset` / `net-status`) for CAKE bufferbloat tuning.
- **Theming**: `scripts/apply-theme.sh` wires Dolphin, Gwenview, EasyEffects, and Noctalia's palette.
- **External-monitor brightness**: `bash scripts/setup-brightness.sh` (sudo required).
- **Bongo Cat keyboard mode**: `bash scripts/setup-noctalia-plugins.sh` (sudo required).
- **Scheduled system snapshots**: `bash scripts/setup-snapper.sh` (sudo required).
- **Optional greeter/timezone templates**: `system/` (includes Noctalia Greeter and greetd configs).
