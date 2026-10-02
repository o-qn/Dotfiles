hl.on("hyprland.start", function()
    -- Noctalia owns bar, notifications, wallpaper, clipboard, polkit, OSD and idle.
    hl.exec_cmd("noctalia --daemon")
end)
