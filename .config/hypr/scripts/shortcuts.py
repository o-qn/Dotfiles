#!/usr/bin/env python3
"""Search the live descriptions. No extra launcher or stale shortcut list."""
import json
import subprocess
import sys

mods = [(64, "Super"), (1, "Shift"), (4, "Ctrl"), (8, "Alt")]
try:
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
except (subprocess.CalledProcessError, json.JSONDecodeError) as error:
    print(f"Cannot read keyboard shortcuts: {error}", file=sys.stderr)
    sys.exit(1)
