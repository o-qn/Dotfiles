hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.config({ input = {
    kb_layout = "us,ara", follow_mouse = 1, sensitivity = 0,
    repeat_rate = 35, repeat_delay = 250,
    touchpad = { natural_scroll = false },
} })
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
