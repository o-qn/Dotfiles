local function bind(keys, action, description, flags)
    flags = flags or {}
    flags.description = description
    hl.bind(keys, action, flags)
end
local function cmd(keys, command, description, flags)
    bind(keys, hl.dsp.exec_cmd(command), description, flags)
end
local function shell(keys, command, description, flags)
    cmd(keys, "noctalia msg " .. command, description, flags)
end
local scripts = '"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/desktop.sh" '

-- Your original muscle memory.
cmd("SUPER + Q", "kitty", "Open terminal")
bind("SUPER + C", hl.dsp.window.close(), "Close focused window")
cmd("SUPER + E", "bash " .. scripts .. "files", "Open PCManFM-Qt")
cmd("SUPER + B", "zen-browser", "Open Zen Browser")
shell("SUPER + R", "panel-toggle launcher", "Application launcher")
shell("SUPER + V", "panel-toggle clipboard", "Clipboard history")
bind("SUPER + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
shell("SUPER + SPACE", "keyboard-layout-cycle", "Switch English / Arabic")
bind("SUPER + P", hl.dsp.window.pseudo(), "Toggle pseudo tiling")
bind("SUPER + J", hl.dsp.layout("togglesplit"), "Change tile split")
shell("SUPER + M", "panel-toggle session", "Session menu")
shell("CTRL + ALT + S", "screenshot-region", "Screenshot region with annotation")
bind("SUPER + S", hl.dsp.workspace.toggle_special("magic"), "Show / hide scratchpad")
bind("SUPER + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), "Send window to scratchpad")

-- Everyday additions.
bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "Toggle fullscreen")
bind("SUPER + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), "Maximize inside bar")
shell("SUPER + L", "session lock", "Lock screen")
shell("SUPER + A", "panel-toggle control-center", "Control center")
shell("SUPER + N", "panel-toggle control-center notifications", "Notification history")
shell("SUPER + CTRL + N", "notification-dnd-toggle", "Toggle Do Not Disturb")
shell("SUPER + W", "panel-toggle wallpaper", "Wallpaper picker")
shell("SUPER + CTRL + S", "settings-toggle", "Desktop settings")
shell("SUPER + CTRL + B", "bar-toggle", "Show / hide bars")
shell("SUPER + CTRL + I", "caffeine-toggle", "Keep awake / restore idle")
shell("ALT + TAB", "window-switcher", "Window switcher")
shell("CTRL + ALT + F", "screenshot-fullscreen", "Screenshot focused monitor")
shell("CTRL + ALT + A", "screenshot-annotate", "Freeze screen and annotate")
cmd("SUPER + F1", "bash " .. scripts .. "help", "Search keyboard shortcuts")
cmd("SUPER + CTRL + Q", "kitty --class desktop-doctor -e bash " .. scripts .. "doctor", "Desktop health check")
cmd("SUPER + ESCAPE", "kitty -e btop", "System monitor")
cmd("SUPER + SHIFT + R", "bash " .. scripts .. "reload", "Validate and reload configuration")

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }), "Focus " .. direction)
    bind("SUPER + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }), "Move window " .. direction)
end
for i = 1, 10 do
    local key = tostring(i % 10)
    -- Existing workspaces stay put; new ones are created on the focused monitor.
    bind("SUPER + " .. key, hl.dsp.focus({ workspace = i }), "Focus workspace " .. i)
    bind("SUPER + SHIFT + " .. key, function()
        local window = hl.get_active_window()
        if not window then return end
        hl.dispatch(hl.dsp.focus({ workspace = i }))
        hl.dispatch(hl.dsp.window.move({ workspace = i, window = window, follow = true }))
    end, "Move window to workspace " .. i .. " and follow it")
end
bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "m+1" }), "Next workspace on this monitor")
bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "m-1" }), "Previous workspace on this monitor")
bind("SUPER + mouse:272", hl.dsp.window.drag(), "Drag window", { mouse = true })
bind("SUPER + mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

-- Noctalia supplies native audio/media controls and matching OSDs.
shell("XF86AudioRaiseVolume", "volume-up 5", "Volume up", { locked = true, repeating = true })
shell("XF86AudioLowerVolume", "volume-down 5", "Volume down", { locked = true, repeating = true })
shell("XF86AudioMute", "volume-mute", "Mute speakers", { locked = true })
shell("XF86AudioMicMute", "mic-mute", "Mute microphone", { locked = true })
shell("XF86AudioNext", "media next", "Next track", { locked = true })
shell("XF86AudioPrev", "media previous", "Previous track", { locked = true })
shell("XF86AudioPlay", "media toggle", "Play / pause", { locked = true })
shell("XF86AudioPause", "media toggle", "Play / pause", { locked = true })
shell("XF86MonBrightnessUp", "brightness-up", "Brightness up", { locked = true, repeating = true })
shell("XF86MonBrightnessDown", "brightness-down", "Brightness down", { locked = true, repeating = true })

-- Keep a usable desktop when the portrait display is powered off.
bind("SUPER + CTRL + M", toggle_portrait_monitor, "Toggle portrait monitor")
