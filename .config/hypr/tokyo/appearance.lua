hl.config({
    general = {
        gaps_in = 5, gaps_out = 10, border_size = 2,
        resize_on_border = true, allow_tearing = false, layout = "dwindle",
        col = {
            active_border = { colors = { "rgba(7aa2f7ee)", "rgba(bb9af7ee)" }, angle = 45 },
            inactive_border = "rgba(414868aa)",
        },
    },
    decoration = {
        rounding = 12, rounding_power = 2,
        active_opacity = 1, inactive_opacity = 1, fullscreen_opacity = 1,
        shadow = { enabled = true, range = 18, render_power = 3, color = 0x9916161e },
        -- Blur is available to the apps and shell surfaces explicitly allowed in rules.lua.
        blur = { enabled = true, size = 4, passes = 2, vibrancy = 0.12,
            noise = 0.008, brightness = 1, contrast = 1, popups = true, special = true },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true, disable_splash_rendering = true, vrr = 1 },
    xwayland = { force_zero_scaling = true },
    group = {
        col = { border_active = "rgb(bb9af7)", border_inactive = "rgb(414868)" },
        groupbar = {
            font_family = "Noto Sans", font_size = 12,
            text_color = "rgb(1a1b26)", text_color_inactive = "rgb(c0caf5)",
            col = { active = "rgb(bb9af7)", inactive = "rgb(24283b)" },
        },
    },
})
hl.curve("tokyoEase", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("tokyoQuick", { type = "bezier", points = { { 0.15, 0 }, { 0.10, 1 } } })
hl.animation({ leaf = "global", enabled = true, speed = 4, bezier = "tokyoEase" })
hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "tokyoEase" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.5, bezier = "tokyoEase" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "tokyoEase", style = "popin 96%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "tokyoQuick", style = "popin 96%" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "tokyoQuick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "tokyoEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "tokyoEase", style = "slide" })
