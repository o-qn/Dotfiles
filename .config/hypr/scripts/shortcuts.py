#!/usr/bin/env python3
"""Search the live descriptions. No extra launcher or stale shortcut list."""
import json
import os
import pathlib
import re
import subprocess
import sys

mods = [(64, "Super"), (1, "Shift"), (4, "Ctrl"), (8, "Alt")]


def is_niri() -> bool:
    sock = os.environ.get("NIRI_SOCKET", "")
    if not sock or not pathlib.Path(sock).is_socket():
        return False
    return subprocess.run(
        ["niri", "msg", "version"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ).returncode == 0


def is_umbriel() -> bool:
    return subprocess.run(
        ["umbriel", "outputs", "-j"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    ).returncode == 0


UMBRIEL_ACTION_DESCRIPTIONS = {
    "spawn noctalia msg panel-toggle launcher": "Application launcher",
    "overview-toggle": "Toggle workspace overview",
    "cheatsheet-toggle": "Toggle Umbriel keybind cheatsheet",
    "spawn noctalia msg panel-toggle clipboard": "Clipboard history",
    "spawn noctalia msg panel-toggle session": "Session menu",
    "spawn noctalia msg panel-toggle control-center": "Control center",
    "spawn noctalia msg panel-toggle control-center notifications": "Notification history",
    "spawn noctalia msg notification-dnd-toggle": "Toggle Do Not Disturb",
    "spawn noctalia msg panel-toggle wallpaper": "Wallpaper picker",
    "spawn noctalia msg settings-toggle": "Desktop settings",
    "spawn noctalia msg bar-toggle": "Show / hide bars",
    "spawn noctalia msg caffeine-toggle": "Keep awake / restore idle",
    "spawn noctalia msg session lock": "Lock screen",
    "spawn noctalia msg window-switcher": "Window switcher",
    "spawn noctalia msg screenshot-region": "Screenshot region with annotation",
    "spawn noctalia msg screenshot-fullscreen": "Screenshot focused monitor",
    "spawn noctalia msg screenshot-annotate": "Freeze screen and annotate",
    "spawn noctalia msg volume-up 5": "Volume up",
    "spawn noctalia msg volume-down 5": "Volume down",
    "spawn noctalia msg volume-mute": "Mute speakers",
    "spawn noctalia msg mic-mute": "Mute microphone",
    "spawn noctalia msg media next": "Next track",
    "spawn noctalia msg media previous": "Previous track",
    "spawn noctalia msg media toggle": "Play / pause",
    "spawn noctalia msg brightness-up": "Brightness up",
    "spawn noctalia msg brightness-down": "Brightness down",
    "spawn kitty": "Open terminal",
    "spawn kitty -e btop": "System monitor",
    "spawn ~/.config/hypr/scripts/desktop.sh files": "Open Nemo",
    "spawn ~/.config/hypr/scripts/desktop.sh browser": "Open Zen Browser",
    "spawn ~/.config/hypr/scripts/desktop.sh help": "Search keyboard shortcuts",
    "spawn ~/.config/hypr/scripts/desktop.sh reload": "Validate and reload configuration",
    "spawn ~/.local/bin/umbriel-toggle-vrr": "Cycle Variable Refresh Rate (VRR) mode",
    "config-reload": "Reload Umbriel configuration",
    "output-toggle DP-3": "Toggle portrait monitor (DP-3)",
    "session-quit": "Quit Umbriel session",
    "keyboard-layout-next": "Switch English / Arabic",
    "window-close": "Close focused window",
    "window-toggle-floating": "Toggle floating",
    "window-focus-switch-floating": "Switch focus between floating and tiling",
    "window-toggle-fullscreen": "Toggle fullscreen",
    "window-toggle-maximize": "Maximize column",
    "window-cycle-primary-extent": "Cycle preset column width",
    "column-center": "Center column",
    "window-cycle-secondary-extent": "Cycle preset window height",
    "window-toggle-pinned": "Pin / unpin floating window",
    "column-toggle-tabbed": "Toggle tabbed column display",
    "window-consume-or-expel-left": "Stack / unstack window left",
    "window-consume-or-expel-right": "Stack / unstack window right",
    "window-consume-from-right": "Consume window from right into column",
    "window-consume-right": "Expel window to column on the right",
    "workspace-set-layout toggle dwindle scrolling master stacking": "Cycle workspace layout (Dwindle/Scroll/Master/Stack)",
    "workspace-set-layout dwindle": "Set workspace layout: Dwindle",
    "workspace-set-layout scrolling": "Set workspace layout: Scrolling",
    "workspace-set-layout master": "Set workspace layout: Master",
    "workspace-set-layout stacking": "Set workspace layout: Stacking",
    "layout-toggle-split": "Toggle Dwindle split direction",
    "layout-master-count-decrease": "Decrease Master window count",
    "layout-master-count-increase": "Increase Master window count",
    "spawn ~/.local/bin/umbriel-effects border cycle": "Cycle window border style (Solid / Pulse / Audio)",
    "spawn ~/.local/bin/umbriel-effects border toggle": "Toggle animated window border effect on / off",
    "spawn ~/.local/bin/umbriel-effects cursor cycle": "Cycle mouse cursor effect (Normal / Trail / Glow)",
    "column-move-left": "Move column left (same monitor)",
    "column-move-right": "Move column right (same monitor)",
    "column-move-to-output-left": "Move column to monitor left",
    "column-move-to-output-right": "Move column to monitor right",
    "column-move-to-output-up": "Move column to monitor up",
    "column-move-to-output-down": "Move column to monitor down",
    "column-move-to-workspace-next": "Move column to next workspace",
    "column-move-to-workspace-previous": "Move column to previous workspace",
    "output-focus-next": "Focus next monitor",
    "window-move-to-output-next": "Move window to next monitor",
    "window-modify-primary-extent -0.1": "Shrink column width (-10%)",
    "window-modify-primary-extent 0.1": "Grow column width (+10%)",
    "window-modify-secondary-extent -0.1": "Shrink window height (-10%)",
    "window-modify-secondary-extent 0.1": "Grow window height (+10%)",
    "window-focus-or-output-left": "Focus left",
    "window-focus-or-output-right": "Focus right",
    "window-focus-or-workspace-up": "Focus up",
    "window-focus-or-workspace-down": "Focus down",
    "column-focus-first": "Focus first column",
    "column-focus-last": "Focus last column",
    "window-move-or-output-left": "Move window / column left",
    "window-move-or-output-right": "Move window / column right",
    "window-move-or-workspace-up": "Move window up",
    "window-move-or-workspace-down": "Move window down",
    "window-move-left": "Move window left (same monitor)",
    "window-move-right": "Move window right (same monitor)",
    "window-move-up": "Move window up (same workspace)",
    "window-move-down": "Move window down (same workspace)",
    "column-move-to-first": "Move column to first position",
    "column-move-to-last": "Move column to last position",
    "output-focus-left": "Focus monitor left",
    "output-focus-right": "Focus monitor right",
    "output-focus-up": "Focus monitor up",
    "output-focus-down": "Focus monitor down",
    "window-move-to-output-left": "Move window to monitor left",
    "window-move-to-output-right": "Move window to monitor right",
    "window-move-to-output-up": "Move window to monitor up",
    "window-move-to-output-down": "Move window to monitor down",
    "workspace-next": "Next workspace on this monitor",
    "workspace-previous": "Previous workspace on this monitor",
    "workspace-focus-last": "Previous active workspace (back & forth)",
    "window-move-to-workspace-next": "Move window to next workspace",
    "window-move-to-workspace-previous": "Move window to previous workspace",
    "window-focus-right": "Focus right",
    "window-focus-left": "Focus left",
}


NIRI_ACTION_DESCRIPTIONS = {
    'spawn "noctalia" "msg" "panel-toggle" "launcher"': "Application launcher",
    "toggle-overview": "Toggle workspace overview",
    'spawn "noctalia" "msg" "panel-toggle" "clipboard"': "Clipboard history",
    'spawn "noctalia" "msg" "panel-toggle" "session"': "Session menu",
    'spawn "noctalia" "msg" "panel-toggle" "control-center"': "Control center",
    'spawn "noctalia" "msg" "panel-toggle" "control-center" "notifications"': "Notification history",
    'spawn "noctalia" "msg" "notification-dnd-toggle"': "Toggle Do Not Disturb",
    'spawn "noctalia" "msg" "panel-toggle" "wallpaper"': "Wallpaper picker",
    'spawn "noctalia" "msg" "settings-toggle"': "Desktop settings",
    'spawn "noctalia" "msg" "bar-toggle"': "Show / hide bars",
    'spawn "noctalia" "msg" "caffeine-toggle"': "Keep awake / restore idle",
    'spawn "noctalia" "msg" "session" "lock"': "Lock screen",
    'spawn "noctalia" "msg" "window-switcher"': "Window switcher",
    'spawn "noctalia" "msg" "screenshot-region"': "Screenshot region with annotation",
    'spawn "noctalia" "msg" "screenshot-fullscreen"': "Screenshot focused monitor",
    'spawn "noctalia" "msg" "screenshot-annotate"': "Freeze screen and annotate",
    'spawn "noctalia" "msg" "volume-up" "5"': "Volume up",
    'spawn "noctalia" "msg" "volume-down" "5"': "Volume down",
    'spawn "noctalia" "msg" "volume-mute"': "Mute speakers",
    'spawn "noctalia" "msg" "mic-mute"': "Mute microphone",
    'spawn "noctalia" "msg" "media" "next"': "Next track",
    'spawn "noctalia" "msg" "media" "previous"': "Previous track",
    'spawn "noctalia" "msg" "media" "toggle"': "Play / pause",
    'spawn "noctalia" "msg" "brightness-up"': "Brightness up",
    'spawn "noctalia" "msg" "brightness-down"': "Brightness down",
    'spawn "kitty"': "Open terminal",
    'spawn "kitty" "-e" "btop"': "System monitor",
    'switch-layout "next"': "Switch English / Arabic",
    "close-window": "Close focused window",
    "toggle-window-floating": "Toggle floating",
    "switch-focus-between-floating-and-tiling": "Switch focus between floating and tiling",
    "fullscreen-window": "Toggle fullscreen",
    "maximize-column": "Maximize column",
    "switch-preset-column-width": "Cycle preset column width",
    "center-column": "Center column",
    "reset-window-height": "Reset window height",
    "consume-or-expel-window-left": "Stack / unstack window left",
    "consume-or-expel-window-right": "Stack / unstack window right",
    "toggle-column-tabbed-display": "Toggle tabbed column display",
    'focus-workspace "scratchpad"': "Show / focus scratchpad workspace",
    'move-window-to-workspace "scratchpad" focus=false': "Send window to scratchpad",
    "consume-window-into-column": "Consume window into column",
    "expel-window-from-column": "Expel window from column",
    'set-column-width "-10%"': "Shrink column width (-10%)",
    'set-column-width "+10%"': "Grow column width (+10%)",
    'set-window-height "-10%"': "Shrink window height (-10%)",
    'set-window-height "+10%"': "Grow window height (+10%)",
    "focus-column-or-monitor-left": "Focus left",
    "focus-column-or-monitor-right": "Focus right",
    "focus-window-or-workspace-up": "Focus up",
    "focus-window-or-workspace-down": "Focus down",
    "focus-column-first": "Focus first column",
    "focus-column-last": "Focus last column",
    "move-column-left-or-to-monitor-left": "Move column left",
    "move-column-right-or-to-monitor-right": "Move column right",
    "move-window-up-or-to-workspace-up": "Move window up",
    "move-window-down-or-to-workspace-down": "Move window down",
    "move-column-left": "Move column left (same monitor)",
    "move-column-right": "Move column right (same monitor)",
    "move-window-up": "Move window up (same workspace)",
    "move-window-down": "Move window down (same workspace)",
    "move-column-to-first": "Move column to first position",
    "move-column-to-last": "Move column to last position",
    "focus-monitor-left": "Focus monitor left",
    "focus-monitor-right": "Focus monitor right",
    "focus-monitor-up": "Focus monitor up",
    "focus-monitor-down": "Focus monitor down",
    "move-column-to-monitor-left": "Move column to monitor left",
    "move-column-to-monitor-right": "Move column to monitor right",
    "move-column-to-monitor-up": "Move column to monitor up",
    "move-column-to-monitor-down": "Move column to monitor down",
    "focus-workspace-down": "Next workspace on this monitor",
    "focus-workspace-up": "Previous workspace on this monitor",
    "move-column-to-workspace-down": "Move column to next workspace",
    "move-column-to-workspace-up": "Move column to previous workspace",
    "focus-column-right": "Focus column right",
    "focus-column-left": "Focus column left",
    "show-hotkey-overlay": "Show Niri hotkey overlay",
    "quit": "Quit Niri session",
}


def format_niri_key(combo: str) -> str:
    parts = combo.split("+")
    formatted = []
    for part in parts:
        if part == "Mod":
            formatted.append("Super")
        else:
            formatted.append(part)
    return " + ".join(formatted)


def describe_niri_action(action: str, title_override: str | None) -> str:
    if title_override:
        return title_override
    if action in NIRI_ACTION_DESCRIPTIONS:
        return NIRI_ACTION_DESCRIPTIONS[action]
    if "desktop.sh" in action:
        if "files" in action:
            return "Open Nemo"
        if "browser" in action:
            return "Open Zen Browser"
        if "help" in action:
            return "Search keyboard shortcuts"
        if "doctor" in action:
            return "Desktop health check"
        if "reload" in action:
            return "Validate and reload configuration"
    if "niri-toggle-vrr" in action:
        return "Toggle Variable Refresh Rate (VRR)"
    if "load-config-file" in action:
        return "Validate and reload configuration"
    if "DP-3" in action:
        return "Toggle portrait monitor"
    m = re.match(r"^focus-workspace (\d+)$", action)
    if m:
        return f"Focus workspace {m.group(1)}"
    m = re.match(r"^move-column-to-workspace (\d+) focus=false$", action)
    if m:
        return f"Send column to workspace {m.group(1)} silently"
    m = re.match(r"^move-column-to-workspace (\d+)$", action)
    if m:
        return f"Move column to workspace {m.group(1)} and follow it"
    return action


def get_niri_rows() -> list[str]:
    config_path = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", pathlib.Path.home() / ".config")) / "niri" / "config.kdl"
    text = config_path.read_text(encoding="utf-8")
    m = re.search(r"(?m)^binds\s*\{(.*?)^\}", text, re.DOTALL)
    if not m:
        return []
    rows = []
    bind_re = re.compile(r"^\s*([A-Za-z0-9_+]+)(.*?)\{\s*(.*?)\s*;\s*\}\s*$")
    title_re = re.compile(r'hotkey-overlay-title="([^"]+)"')
    for line in m.group(1).splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("//"):
            continue
        bm = bind_re.match(line)
        if not bm:
            continue
        combo, props, action = bm.group(1), bm.group(2), bm.group(3)
        tm = title_re.search(props)
        desc = describe_niri_action(action, tm.group(1) if tm else None)
        rows.append(f"{format_niri_key(combo):<32}  {desc}")
    return rows


def describe_umbriel_action(action: str) -> str:
    if action in UMBRIEL_ACTION_DESCRIPTIONS:
        return UMBRIEL_ACTION_DESCRIPTIONS[action]
    if "desktop.sh doctor" in action:
        return "Desktop health check"
    m = re.match(r"^workspace-switch (\d+)$", action)
    if m:
        return f"Focus workspace {m.group(1)}"
    m = re.match(r"^window-move-to-workspace (\d+)$", action)
    if m:
        return f"Move window to workspace {m.group(1)} and follow it"
    m = re.match(r"^window-move-to-workspace-silent (\d+)$", action)
    if m:
        return f"Send window to workspace {m.group(1)} silently"
    return action


def get_umbriel_rows() -> list[str]:
    config_path = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", pathlib.Path.home() / ".config")) / "umbriel" / "config.toml"
    text = config_path.read_text(encoding="utf-8")
    m = re.search(r"(?m)^\[keybinds\]\s*(.*?)\Z", text, re.DOTALL)
    if not m:
        return []
    rows = []
    str_re = re.compile(r'^\s*"([^"]+)"\s*=\s*"([^"]+)"\s*$')
    tbl_re = re.compile(r'^\s*"([^"]+)"\s*=\s*\{.*?\baction\s*=\s*"([^"]+)".*\}\s*$')
    for line in m.group(1).splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        sm = str_re.match(line) or tbl_re.match(line)
        if not sm:
            continue
        combo, action = sm.group(1), sm.group(2)
        rows.append(f"{format_niri_key(combo):<32}  {describe_umbriel_action(action)}")
    return rows


try:
    if is_umbriel():
        rows = get_umbriel_rows()
    elif is_niri():
        rows = get_niri_rows()
    else:
        result = subprocess.run(["hyprctl", "binds", "-j"], check=True, capture_output=True, text=True)
        rows = []
        for bind in json.loads(result.stdout):
            description = bind.get("description", "")
            if not description:
                continue
            parts = [name for mask, name in mods if bind.get("modmask", 0) & mask]
            parts.append(bind.get("key", "") or f'code:{bind.get("keycode", "?")}')
            rows.append(f'{" + ".join(parts):<32}  {description}')
    subprocess.run(["noctalia", "dmenu", "--prompt", "Keyboard shortcuts"], input="\n".join(rows), text=True, check=True)
except (subprocess.CalledProcessError, json.JSONDecodeError, OSError) as error:
    print(f"Cannot read keyboard shortcuts: {error}", file=sys.stderr)
    sys.exit(1)
