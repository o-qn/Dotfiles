-- Match hardware descriptions; portrait LEFT, main RIGHT.
local root = os.getenv("HYPR_CONFIG_ROOT")
    or ((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr")
local marker = root .. "/single-monitor"
local saved = io.open(marker, "r")
local main_only = saved ~= nil
if saved then saved:close() end
local main_desc = "desc:HKC OVERSEAS LIMITED G2721P 0000000000001"
local portrait_desc = "desc:Sceptre Tech Inc Sceptre L24 0000000000000"

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({ output = main_desc, mode = "2560x1440@200Hz", position = "0x0", scale = 1.25, vrr = 2, bitdepth = 10 })
hl.monitor({ output = portrait_desc, mode = "1920x1080@60Hz", position = "-1080x-384",
    scale = 1, transform = 1, vrr = 2, disabled = main_only })
hl.workspace_rule({ workspace = "1", monitor = main_desc, default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = portrait_desc, default = true, persistent = true })

local function find_displays()
    local monitors = hl.get_monitors()
    local main, portrait
    for _, monitor in ipairs(monitors) do
        local description = monitor.description or ""
        if description:find("G2721P", 1, true) then main = monitor end
        if description:find("Sceptre L24", 1, true) then portrait = monitor end
    end
    return main, portrait, monitors[1]
end

local last_layout
local function sync_workspace_homes()
    local main, portrait, first = find_displays()
    if not first then return end
    local home1, home2 = main or first, portrait or main or first
    local layout = home1.name .. ":" .. home2.name
    if last_layout == layout then return end
    last_layout = layout
    -- Rebind only the two reserved workspaces; all others remain dynamic.
    hl.workspace_rule({ workspace = "1", monitor = home1.name, default = true, persistent = true })
    hl.workspace_rule({ workspace = "2", monitor = home2.name,
        default = home2.name ~= home1.name, persistent = true })
    for number, monitor in ipairs({ home1, home2 }) do
        local workspace = hl.get_workspace(number)
        if workspace and (not workspace.monitor or workspace.monitor.name ~= monitor.name) then
            hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = monitor }))
        end
    end
end

local pending = false
local function schedule_sync()
    -- The standalone config verifier has no compositor event loop.
    if #hl.get_monitors() == 0 then return end
    if pending then return end
    pending = true
    hl.timer(function()
        pending = false
        sync_workspace_homes()
    end, { timeout = 150, type = "oneshot" })
end
for _, event in ipairs({ "hyprland.start", "config.reloaded", "monitor.layout_changed" }) do
    hl.on(event, schedule_sync)
end

function toggle_portrait_monitor()
    local main = find_displays()
    if not main_only and not main then
        hl.exec_cmd("noctalia msg notification-show 'Displays' 'Keep the remaining monitor enabled'")
        return
    end
    local next_mode = not main_only
    if next_mode then
        local file, err = io.open(marker, "w")
        if not file then error("Cannot save monitor mode: " .. tostring(err)) end
        file:write("Main monitor only; Super+Ctrl+M restores the portrait display.\n")
        file:close()
    else
        local ok, err = os.remove(marker)
        if not ok then error("Cannot restore monitor mode: " .. tostring(err)) end
    end
    main_only = next_mode
    hl.monitor({ output = portrait_desc, disabled = main_only })
    schedule_sync()
    hl.exec_cmd("noctalia msg notification-show 'Displays' '" ..
        (main_only and "Main monitor only" or "Dual monitor layout restored") .. "'")
end
