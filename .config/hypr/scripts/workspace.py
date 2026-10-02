#!/usr/bin/env python3
"""Create the next unused numbered workspace on the bar's monitor."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import subprocess

def query(command):
    return json.loads(subprocess.check_output(["hyprctl", command, "-j"], text=True))

def create_workspace(monitor=None):
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"))
    with (runtime / "tokyo-workspace.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        monitors = query("monitors")
        target = next((m for m in monitors if m["name"] == monitor or (monitor and monitor in m.get("description", ""))), None) if monitor else None
        target = target or next((m for m in monitors if m["focused"]), None) or next(iter(monitors), None)
        if target is None:
            raise RuntimeError(f"No active monitor available")
        used = {w["id"] for w in query("workspaces") if w["id"] > 0}
        number = 3
        while number in used:
            number += 1
        lua = (
            f'hl.dispatch(hl.dsp.focus({{monitor={int(target["id"])}}})); '
            f'hl.dispatch(hl.dsp.focus({{workspace={number},on_current_monitor=true}}))'
        )
        subprocess.run(["hyprctl", "eval", lua], check=True)
        return number

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["new"])
    parser.add_argument("--monitor", help="Connector or hardware description of the bar monitor")
    arguments = parser.parse_args()
    create_workspace(arguments.monitor)
