#!/usr/bin/env python3
"""Map a rendered Noctalia palette to libcosmic Theme v2 config entries.

COSMIC Files reads these native files, including outside the COSMIC desktop.
Live refresh depends on the installed libcosmic build/settings service.
Only theme colors and the Files theme preference are managed; geometry and app
preferences stay untouched. Hyprland continues to handle glass opacity/blur.
"""
import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import tempfile


def mix(a, b, amount):
    channels = [round(int(a[i:i+2], 16)*(1-amount)+int(b[i:i+2], 16)*amount) for i in (1,3,5)]
    return "#" + "".join(f"{v:02x}" for v in channels)


def color(value):
    if not re.fullmatch(r"#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?", value):
        raise ValueError(f"Invalid color: {value!r}")
    return json.dumps(value + ("ff" if len(value)==7 else ""))


def struct(values):
    return "(\n" + "".join(f"    {key}: {value},\n" for key,value in values.items()) + ")"


def write(path, value):
    content = value + "\n"
    if path.exists() and path.read_text()==content:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        stream.write(content)
        temporary = Path(stream.name)
    os.chmod(temporary, 0o600)
    os.replace(temporary, path)


def apply(palette, config):
    c = palette["colors"]
    for value in c.values():
        color(value)
    mode = palette["mode"]
    if mode not in {"dark", "light"}:
        raise ValueError(f"Unknown theme mode: {mode}")
    fg, muted, border = c["on_surface"], c["on_surface_variant"], c["outline"]
    selected = mix(c["surface_variant"], c["primary"], 0.25)

    def component(base, on=fg, emphasis=None):
        return struct({key:color(value) for key,value in {
            "base":base,
            "hover":mix(base,c["on_surface"],0.10) if base!="#00000000" else c["hover"],
            "pressed":mix(base,c["on_surface"],0.18) if base!="#00000000" else selected,
            "selected":selected, "selected_text":fg, "focus":emphasis or c["primary"],
            "divider":border, "on":on, "disabled":c["surface_variant"],
            "on_disabled":muted, "border":border, "disabled_border":border,
        }.items()})

    entries = {}
    for name, base in [("background",c["surface"]),("primary",c["surface_variant"]),("secondary",c["hover"])]:
        container = struct({"base":color(base),"component":component(c["surface_variant"]),
                            "divider":color(border),"on":color(fg),"small_widget":color(muted)})
        entries[name] = container
        entries["transparent_"+name] = container
    for key in ["button","icon_button","list_button","text_button"]:
        entries[key] = component(c["surface_variant"] if key=="button" else "#00000000")
    entries["link_button"] = component("#00000000",c["primary"])
    for key, base, on in [("accent",c["primary"],c["on_primary"]),
                          ("success",c["terminal_normal_green"],c["surface"]),
                          ("destructive",c["error"],c["on_error"]),
                          ("warning",c["terminal_normal_yellow"],c["surface"])]:
        entries[key] = component(base,on,base)
        entries[key+"_button"] = component(base,on,base)
    colors = {"bright_red":c["error"],"bright_green":c["terminal_normal_green"],
              "bright_orange":c["terminal_normal_yellow"],"gray_1":c["surface_variant"],"gray_2":c["hover"]}
    colors.update({f"neutral_{i}":mix(c["surface"],fg,i/10) for i in range(11)})
    colors.update({"accent_blue":c["terminal_normal_blue"],"accent_indigo":c["primary"],
        "accent_purple":c["secondary"],"accent_pink":c["terminal_normal_magenta"],
        "accent_red":c["error"],"accent_orange":c["terminal_normal_yellow"],
        "accent_yellow":c["terminal_normal_yellow"],"accent_green":c["terminal_normal_green"],
        "accent_warm_grey":muted,"ext_warm_grey":muted,"ext_orange":c["terminal_normal_yellow"],
        "ext_yellow":c["terminal_normal_yellow"],"ext_blue":c["tertiary"],
        "ext_purple":c["secondary"],"ext_pink":c["terminal_normal_magenta"],"ext_indigo":c["primary"]})
    entries["palette"] = struct({"name":json.dumps("Noctalia"),**{k:color(v) for k,v in colors.items()}})
    entries.update({"name":json.dumps("Noctalia"), "is_dark":str(mode=="dark").lower(),
                    "is_high_contrast":"false", "shade":color(c["shadow"]+"b3"),
                    "accent_text":"Some("+color(c["primary"])+")",
                    "control_tint":"None", "text_tint":"None"})
    theme = config / ("com.system76.CosmicTheme.Dark" if mode=="dark" else "com.system76.CosmicTheme.Light") / "v2"
    # Write the palette before selecting the mode, avoiding a flash of the defaults.
    for key, value in entries.items():
        write(theme/key,value)
    write(config/"com.system76.CosmicTheme.Mode/v1/is_dark",str(mode=="dark").lower())
    write(config/"com.system76.CosmicFiles/v1/app_theme","System")
    print(f"COSMIC theme synchronized: {mode}, accent {c['primary']}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("palette",type=Path)
    parser.add_argument("--config-root",type=Path)
    args = parser.parse_args()
    config = args.config_root or Path(os.environ.get("XDG_CONFIG_HOME",Path.home()/".config"))/"cosmic"
    state = Path(os.environ.get("XDG_STATE_HOME",Path.home()/".local/state"))/"noctalia"
    state.mkdir(parents=True,exist_ok=True)
    with (state/"cosmic-theme.lock").open("w") as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        apply(json.loads(args.palette.read_text()),config)


if __name__=="__main__":
    main()
