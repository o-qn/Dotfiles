-- Hyprland / Noctalia desktop
-- Your familiar shortcuts, with one shell owning the desktop services.
local root = os.getenv("HYPR_CONFIG_ROOT")
    or ((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr")
for _, module in ipairs({ "monitors", "appearance", "input", "rules", "keybinds", "autostart" }) do
    dofile(root .. "/config/" .. module .. ".lua")
end

-- Apply generated colors without registering the palette as a config dependency.
-- Noctalia calls this function after rendering a palette, avoiding a full reload.
function apply_noctalia_theme()
    local path = root .. "/noctalia.lua"
    local file = io.open(path, "r")
    if not file then return end
    local source = file:read("*a")
    file:close()
    local palette = assert(load(source, "@" .. path, "t"))()
    palette.apply_theme()
end
apply_noctalia_theme()
