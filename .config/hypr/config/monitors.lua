-- Match hardware descriptions; portrait LEFT, main RIGHT.
local root = os.getenv("HYPR_CONFIG_ROOT")
    or ((os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/hypr")
local displays = {
    { role = "main", needle = "G2721P", selector = "desc:HKC OVERSEAS LIMITED G2721P 0000000000001",
        marker = root .. "/portrait-only", workspace_file = root .. "/main-workspace", home = 1,
        settings = { mode = "2560x1440@200Hz", position = "0x0", scale = 1.25, vrr = 2, bitdepth = 10 } },
    { role = "portrait", needle = "Sceptre L24", selector = "desc:Sceptre Tech Inc Sceptre L24 0000000000000",
        marker = root .. "/single-monitor", workspace_file = root .. "/portrait-workspace", home = 2,
        settings = { mode = "1920x1080@60Hz", position = "-1080x-384", scale = 1, transform = 1, vrr = 2 } },
}
local function apply_display(display, disabled)
    local settings = { output = display.selector, disabled = disabled }
    for key, value in pairs(display.settings) do settings[key] = value end
    hl.monitor(settings)
end
local function exists(path)
    local file = io.open(path, "r")
    if not file then return false end
    file:close()
    return true
end
local function find_displays()
    local monitors = hl.get_monitors()
    local found = {}
    for _, monitor in ipairs(monitors) do
        for _, display in ipairs(displays) do
            if (monitor.description or ""):find(display.needle, 1, true) then found[display.role] = monitor end
        end
    end
    return found, monitors
end
local function remember(display, monitor)
    local workspace = monitor and monitor.active_workspace
    if not workspace or workspace.id <= 0 or workspace.id == (3 - display.home) then return end
    display.last_workspace = workspace.id
    local file = io.open(display.workspace_file, "w")
    if file then file:write(tostring(workspace.id), "\n"); file:close() end
end
local initial = find_displays()
for _, display in ipairs(displays) do
    display.last_workspace = display.home
    display.generation = 0
    local file = io.open(display.workspace_file, "r")
    if file then display.last_workspace = tonumber(file:read("*l")) or display.home; file:close() end
    local monitor = initial[display.role]
    display.ready = monitor ~= nil
    if file and monitor and monitor.active_workspace and hl.get_workspace(display.last_workspace)
        and monitor.active_workspace.id ~= display.last_workspace then
        display.ready = false
    elseif monitor then
        remember(display, monitor)
    end
end

local main_only = exists(displays[2].marker)
-- At boot the main output is enabled first, so an absent portrait cannot leave a black desktop.
local portrait_only = not main_only and exists(displays[1].marker) and initial.portrait ~= nil
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
apply_display(displays[1], portrait_only)
apply_display(displays[2], main_only)
hl.workspace_rule({ workspace = "1", monitor = displays[1].selector, default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = displays[2].selector, default = true, persistent = true })

local last_layout
local function sync_workspace_homes()
    local found, monitors = find_displays()
    if #monitors == 0 then
        os.remove(displays[1].marker)
        apply_display(displays[1], false)
        return
    end
    -- Honor portrait-only mode after startup, and recover if its sole display disappears.
    if exists(displays[1].marker) then
        if found.portrait and found.main then
            displays[1].ready = false
            apply_display(displays[1], true)
            return
        elseif not found.portrait then
            os.remove(displays[1].marker)
            apply_display(displays[1], false)
        end
    end
    local homes = { found.main or monitors[1], found.portrait or found.main or monitors[1] }
    local layout = homes[1].name .. ":" .. homes[2].name
    -- X11/Proton games need an explicit primary display; reconnect order is unstable.
    local primary = root .. "/scripts/displays.py"
    hl.exec_cmd("python3 " .. "'" .. primary:gsub("'", "'\\''") .. "' primary")
    local returning = false
    for _, display in ipairs(displays) do
        if found[display.role] and not display.ready and not display.restoring then returning = true end
    end
    if last_layout == layout and not returning then return end
    last_layout = layout
    for index, home in ipairs(homes) do
        hl.workspace_rule({ workspace = tostring(index), monitor = home.name,
            default = index == 1 or homes[1].name ~= homes[2].name, persistent = true })
        local workspace = hl.get_workspace(index)
        if workspace and (not workspace.monitor or workspace.monitor.name ~= home.name) then
            hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = home }))
        end
    end
    for _, display in ipairs(displays) do
        local monitor = found[display.role]
        if monitor and not display.ready and not display.restoring then
            display.restoring = true
            local generation = display.generation
            -- Select after asynchronous workspace-rule refresh has settled.
            hl.timer(function()
                if generation ~= display.generation then return end
                display.restoring = false
                local current, active = find_displays()
                local target = current[display.role]
                if not target then return end
                local focused, focused_workspace
                for _, candidate in ipairs(active) do
                    if candidate.focused then focused, focused_workspace = candidate, candidate.active_workspace; break end
                end
                local cursor = hl.get_cursor_pos()
                local workspace = hl.get_workspace(display.last_workspace) or hl.get_workspace(display.home)
                if workspace then
                    if not workspace.monitor or workspace.monitor.name ~= target.name then
                        hl.dispatch(hl.dsp.workspace.move({ workspace = workspace, monitor = target }))
                    end
                    target:set_workspace({ workspace = workspace })
                end
                if focused and focused.name ~= target.name then
                    if not focused_workspace or not focused_workspace.monitor
                        or focused_workspace.monitor.name ~= focused.name then
                        focused_workspace = hl.get_workspace(display.home == 1 and 2 or 1)
                    end
                    if focused_workspace then focused:set_workspace({ workspace = focused_workspace }) end
                    hl.dispatch(hl.dsp.focus({ monitor = focused }))
                    hl.dispatch(hl.dsp.cursor.move({ x = cursor.x, y = cursor.y }))
                end
                display.ready = true
                remember(display, target)
            end, { timeout = 350, type = "oneshot" })
        elseif not monitor then
            display.ready = false
        elseif display.ready then
            remember(display, monitor)
        end
    end
end

hl.on("workspace.active", function(workspace)
    if not workspace.monitor then return end
    for _, display in ipairs(displays) do
        if display.ready and (workspace.monitor.description or ""):find(display.needle, 1, true) then
            local id, generation = workspace.id, display.generation
            hl.timer(function()
                local current = find_displays()
                local monitor = current[display.role]
                if display.ready and generation == display.generation and monitor and monitor.active_workspace
                    and monitor.active_workspace.id == id then remember(display, monitor) end
            end, { timeout = 50, type = "oneshot" })
        end
    end
end)
local function reset_display(monitor)
    for _, display in ipairs(displays) do
        if (monitor.description or ""):find(display.needle, 1, true) then
            display.ready, display.restoring = false, false
            display.generation = display.generation + 1
        end
    end
end
hl.on("monitor.removed", function(monitor)
    reset_display(monitor)
    if #hl.get_monitors() == 0 then
        os.remove(displays[1].marker)
        apply_display(displays[1], false)
    end
end)
hl.on("monitor.added", reset_display)
local pending = false
local function schedule_sync()
    -- Offline verification has no compositor event loop.
    if #hl.get_monitors() == 0 then return end
    if pending then return end
    pending = true
    hl.timer(function() pending = false; sync_workspace_homes() end, { timeout = 150, type = "oneshot" })
end
for _, event in ipairs({ "hyprland.start", "config.reloaded", "monitor.layout_changed" }) do
    hl.on(event, schedule_sync)
end

function toggle_display(role)
    local found, monitors = find_displays()
    local display
    for _, candidate in ipairs(displays) do if candidate.role == role then display = candidate end end
    if not display then error("Unknown display") end
    local monitor = found[role]
    if monitor and #monitors < 2 then error("Keep the remaining monitor enabled") end
    if monitor then
        remember(display, monitor)
        local file, err = io.open(display.marker, "w")
        if not file then error("Cannot save monitor mode: " .. tostring(err)) end
        file:write("This display is disabled. Restore it from Control Center > Displays.\n"); file:close()
    elseif exists(display.marker) then
        local ok, err = os.remove(display.marker)
        if not ok then error("Cannot restore monitor mode: " .. tostring(err)) end
    end
    display.ready = false
    apply_display(display, monitor ~= nil)
    schedule_sync()
end
function toggle_portrait_monitor()
    local found, monitors = find_displays()
    if found.portrait and #monitors < 2 then
        hl.exec_cmd("noctalia msg notification-show 'Displays' 'Keep the remaining monitor enabled'")
        return
    end
    toggle_display("portrait")
end
