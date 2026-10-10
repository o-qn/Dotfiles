#!/usr/bin/env python3
"""Noctalia display controls; Hyprland owns mode, fallback and workspace memory."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import time

DISPLAYS = (("main", "Main", "G2721P"), ("portrait", "Portrait", "Sceptre L24"))

def query(command):
    return json.loads(subprocess.check_output(["hyprctl", "-j", *command], text=True))

def status():
    active = query(["monitors"])
    connected = query(["monitors", "all"])
    names = {monitor["name"] for monitor in active}
    displays = []
    for role, label, model in DISPLAYS:
        monitor = next((m for m in connected if model in m.get("description", "")), None)
        enabled = monitor is not None and monitor["name"] in names
        workspace = monitor.get("activeWorkspace", {}).get("id", 0) if monitor else 0
        displays.append({"role": role, "label": label, "connector": monitor["name"] if monitor else "",
                         "connected": monitor is not None, "enabled": enabled,
                         "workspace": workspace if enabled else 0,
                         "can_disable": enabled and len(active) > 1})
    return {"displays": displays}

def set_primary():
    active = query(["monitors"])
    if not active:
        return {"primary": None}
    target = next((m for m in active if "G2721P" in m.get("description", "")), active[0])
    # XWayland clients can otherwise choose the first output after a reconnect.
    for attempt in range(5):
        result = subprocess.run(["xrandr", "--query"], capture_output=True, text=True)
        output = next((line for line in result.stdout.splitlines()
                       if line.startswith(target["name"] + " connected ")), None)
        if output is not None:
            if "primary" in output.split():
                return {"primary": target["name"]}
            result = subprocess.run(["xrandr", "--output", target["name"], "--primary"],
                                    capture_output=True, text=True)
        time.sleep(0.1)
    raise RuntimeError(result.stderr.strip() or "Cannot confirm XWayland primary display")

def set_enabled(role, enabled):
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    with (runtime / "desktop-displays.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        current = status()
        display = next(d for d in current["displays"] if d["role"] == role)
        if not display["connected"]:
            raise RuntimeError("This monitor is disconnected")
        if display["enabled"] == enabled:
            return current
        if not enabled and not display["can_disable"]:
            raise RuntimeError("Keep the remaining monitor enabled")
        code = f"toggle_display({json.dumps(role)})"
        result = subprocess.run(["hyprctl", "eval", code], capture_output=True, text=True, check=True)
        if result.stdout.strip() != "ok":
            raise RuntimeError(result.stdout.strip() or result.stderr.strip())
        for _ in range(30):
            time.sleep(0.1)
            current = status()
            if next(d for d in current["displays"] if d["role"] == role)["enabled"] == enabled:
                # Let workspace restoration and native panel recreation settle.
                time.sleep(0.6)
                return status()
        raise RuntimeError("Monitor change did not complete")

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("status", "set", "primary"), default="status", nargs="?")
    parser.add_argument("role", choices=("main", "portrait"), nargs="?")
    parser.add_argument("mode", choices=("on", "off"), nargs="?")
    args = parser.parse_args()
    if args.action == "set" and (args.role is None or args.mode is None):
        parser.error("set requires a role and on/off")
    try:
        if args.action == "primary":
            result = set_primary()
        elif args.action == "set":
            result = set_enabled(args.role, args.mode == "on")
        else:
            result = status()
    except (RuntimeError, OSError, subprocess.SubprocessError, ValueError) as error:
        print(json.dumps({"error": str(error)}))
        return 1
    print(json.dumps(result))
    return 0

if __name__ == "__main__":
    sys.exit(main())
