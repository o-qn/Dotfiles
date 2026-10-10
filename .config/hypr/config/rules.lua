-- Glass is opt-in: ordinary apps, videos and games stay opaque and unblurred.
hl.window_rule({ name = "default-no-glass", match = { class = ".*" }, no_blur = true })
hl.window_rule({
    name = "kitty-glass", match = { class = "^(kitty|desktop-doctor)$" },
    no_blur = false,
})
hl.window_rule({
    name = "dolphin-glass", match = { class = "^(org[.]kde[.]dolphin|dolphin)$" },
    no_blur = false, opacity = "0.90 override 0.84 override 1.0 override",
})
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })
hl.window_rule({
    name = "xwayland-drag-fix",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})
hl.window_rule({ name = "desktop-tools", match = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|qt6ct)$" }, float = true, center = true, size = "900 650" })
hl.window_rule({ name = "desktop-reference", match = { class = "^(desktop-doctor)$" }, float = true, center = true, size = "1000 740" })
hl.window_rule({ name = "scratchpad-style", match = { workspace = "special:magic" }, rounding = 16 })
hl.window_rule({
    name = "zen-no-glass", match = { class = "^(zen|Zen|zen-browser|zen-bin)$" },
    opaque = true, no_blur = true, force_rgbx = true,
})
hl.window_rule({
    name = "stremio-no-glass", match = { class = "^(com[.]stremio[.]Stremio|[Ss]tremio)$" },
    opaque = true, no_blur = true, force_rgbx = true,
    opacity = "1.0 override 1.0 override 1.0 override",
})
-- Native Noctalia blur is preferred; this covers its layer surfaces on Hyprland.
hl.layer_rule({ name = "noctalia-blur", match = { namespace = "noctalia.*" }, blur = true, ignore_alpha = 0.15 })

-- Games open on the main display, even when launched from the portrait monitor.
local game_monitor = "desc:HKC OVERSEAS LIMITED G2721P 0000000000001"
hl.window_rule({ name = "steam-games-main", match = { initial_class = "^steam_app_[0-9]+$" }, monitor = game_monitor })
hl.window_rule({ name = "native-games-main", match = { content = "game" }, monitor = game_monitor })
