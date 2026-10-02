-- Tokyo Night / Hyprland 0.56 / Noctalia 5.2
-- Your familiar shortcuts, with one shell owning the desktop services.
local root = os.getenv("TOKYO_NIGHT_CONFIG_ROOT")
    or ((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr")
for _, module in ipairs({ "monitors", "appearance", "input", "rules", "keybinds", "autostart" }) do
    dofile(root .. "/tokyo/" .. module .. ".lua")
end

-- Noctalia renders this module whenever the palette changes.
local colors = io.open(root .. "/noctalia.lua", "r")
if colors then
    colors:close()
    package.path = root .. "/?.lua;" .. package.path
    require("noctalia").apply_theme()
end
