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

-- Remember the portrait's last workspace across hotplug and config reloads.
local workspace_file = root .. "/portrait-workspace"
local portrait_workspace = 2
local previous = io.open(workspace_file, "r")
if previous then
    portrait_workspace = tonumber(previous:read("*l")) or 2
    previous:close()
end
local function remember_portrait(portrait)
    local workspace = portrait and portrait.active_workspace
    if not workspace or workspace.id <= 1 then return end
    portrait_workspace = workspace.id
    local file = io.open(workspace_file, "w")
    if file then file:write(tostring(portrait_workspace), "\n"); file:close() end
end
local _, initial_portrait = find_displays()
local portrait_ready = initial_portrait ~= nil
if previous and initial_portrait and initial_portrait.active_workspace
    and hl.get_workspace(portrait_workspace)
    and initial_portrait.active_workspace.id ~= portrait_workspace then
    -- A reload may re-enable the output before the Lua callbacks are installed.
    portrait_ready = false
elseif portrait_ready then
    remember_portrait(initial_portrait)
end
local last_layout
local restore_pending = false
local function sync_workspace_homes()
    local main, portrait, first = find_displays()
    if not first then return end
    local home1, home2 = main or first, portrait or main or first
    local layout = home1.name .. ":" .. home2.name
    local returning = portrait ~= nil and not portrait_ready
    if last_layout == layout and (not returning or restore_pending) then return end
    portrait_ready = false
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
    if returning then
        restore_pending = true
        -- Workspace rules refresh asynchronously. Select the saved workspace
        -- after that refresh, so the default cannot replace it again.
        hl.timer(function()
            restore_pending = false
            local _, target = find_displays()
            if not target then return end
            local focused, focused_workspace
            for _, monitor in ipairs(hl.get_monitors()) do
                if monitor.focused then
                    focused, focused_workspace = monitor, monitor.active_workspace
                    break
                end
            end
            local cursor = hl.get_cursor_pos()
            local workspace = hl.get_workspace(portrait_workspace) or hl.get_workspace(2)
            if workspace then
                if not workspace.monitor or workspace.monitor.name ~= target.name then
                    hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = target }))
                end
                target:set_workspace({ workspace = workspace })
            end
            if focused and focused.name ~= target.name then
                if not focused_workspace or not focused_workspace.monitor
                    or focused_workspace.monitor.name ~= focused.name then
                    focused_workspace = hl.get_workspace(1)
                end
                if focused_workspace then focused:set_workspace({ workspace = focused_workspace }) end
                hl.dispatch(hl.dsp.focus({ monitor = focused }))
                hl.dispatch(hl.dsp.cursor.move({ x = cursor.x, y = cursor.y }))
            end
            portrait_ready = true
            remember_portrait(target)
        end, { timeout = 350, type = "oneshot" })
    else
        portrait_ready = portrait ~= nil
        if portrait_ready then remember_portrait(portrait) end
    end
end

hl.on("workspace.active", function(workspace)
    if not portrait_ready or not workspace.monitor then return end
    if (workspace.monitor.description or ""):find("Sceptre L24", 1, true) then
        local id = workspace.id
        -- Disconnect migrations can briefly activate a replacement workspace.
        -- Record only after the monitor transition has settled.
        hl.timer(function()
            local _, portrait = find_displays()
            if portrait_ready and portrait and portrait.active_workspace
                and portrait.active_workspace.id == id then
                remember_portrait(portrait)
            end
        end, { timeout = 50, type = "oneshot" })
    end
end)
hl.on("monitor.removed", function(monitor)
    if (monitor.description or ""):find("Sceptre L24", 1, true) then portrait_ready = false end
end)
hl.on("monitor.added", function(monitor)
    if (monitor.description or ""):find("Sceptre L24", 1, true) then portrait_ready = false end
end)

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
    local main, portrait = find_displays()
    if not main_only and not main then
        hl.exec_cmd("noctalia msg notification-show 'Displays' 'Keep the remaining monitor enabled'")
        return
    end
    local next_mode = not main_only
    if next_mode then
        remember_portrait(portrait)
        portrait_ready = false
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
