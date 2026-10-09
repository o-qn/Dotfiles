hl.on("hyprland.start", function()
    -- Noctalia owns bar, notifications, wallpaper, clipboard, polkit, OSD and idle.
    hl.exec_cmd("noctalia --daemon")
    -- Keep saved audio presets available in Noctalia's Audio tab.
    hl.exec_cmd("easyeffects --service-mode --hide-window")
end)
