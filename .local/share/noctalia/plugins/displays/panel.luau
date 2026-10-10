--!nonstrict
local script = (noctalia.getenv("XDG_CONFIG_HOME") or (noctalia.getenv("HOME") .. "/.config"))
    .. "/hypr/scripts/displays.py"
local displays = {}
local errorMessage = ""
local busy = false
local opened = false
local querying = false
local render
local function accept(result)
    local data, err = noctalia.json.decode(result.stdout or "")
    if type(data) ~= "table" then
        errorMessage = result.stderr or err or "Cannot read display status"
    elseif data.error then
        errorMessage = data.error
    else
        displays = data.displays or {}
        errorMessage = ""
    end
end
local function refresh()
    if not opened or busy or querying then return end
    querying = true
    noctalia.runAsync({"python3", script, "status"}, function(result)
        querying = false
        if not opened then return end
        accept(result)
        render()
    end)
end
local function change(display)
    if busy then return end
    busy = true
    errorMessage = ""
    render()
    noctalia.runAsync({"python3", script, "set", display.role, display.enabled and "off" or "on"}, function(result)
        busy = false
        if not opened then return end
        accept(result)
        render()
    end)
end
render = function()
    local children = {
        ui.row({align = "center", gap = 8}, {
            ui.label({text = "Displays", fontSize = 18, fontWeight = "bold", flexGrow = 1}),
            ui.button({glyph = "close", variant = "ghost", onClick = function() panel.close() end}),
        }),
    }
    for _, display in ipairs(displays) do
        local detail = not display.connected and "Disconnected"
            or (display.enabled and ("On · Workspace " .. tostring(display.workspace)) or "Off")
        table.insert(children, ui.row({key = display.role, align = "center", gap = 12,
            padding = 14, radius = 12, fill = "surface_variant/0.6"}, {
            ui.glyph({name = "device-desktop", size = 25, color = display.enabled and "primary" or "on_surface_variant"}),
            ui.column({gap = 4, flexGrow = 1}, {
                ui.label({text = display.label .. (display.connector ~= "" and (" · " .. display.connector) or ""), fontWeight = "bold"}),
                ui.label({text = detail, fontSize = 12, color = "on_surface_variant"}),
            }),
            ui.button({text = display.enabled and "Turn off" or "Turn on", glyph = "power", variant = "outline",
                enabled = not busy and display.connected and (not display.enabled or display.can_disable),
                tooltip = display.enabled and not display.can_disable and "Keep the remaining display enabled" or "",
                onClick = function() change(display) end}),
        }))
    end
    if #displays == 0 then table.insert(children, ui.label({text = "Loading displays…", color = "on_surface_variant"})) end
    if errorMessage ~= "" then table.insert(children, ui.label({text = errorMessage, color = "error", maxLines = 2})) end
    table.insert(children, ui.spacer({flexGrow = 1}))
    table.insert(children, ui.button({text = "Brightness controls", glyph = "brightness", variant = "ghost",
        onClick = function()
            panel.close()
            noctalia.runAsync({"noctalia", "msg", "panel-open", "control-center", "monitor"})
        end}))
    panel.render(ui.column({gap = 12, align = "stretch", flexGrow = 1}, children))
end
function onOpen(_context)
    opened, busy, querying = true, false, false
    panel.setWantsSecondTicks(true)
    render()
    refresh()
end
function onClose()
    opened = false
    panel.setWantsSecondTicks(false)
end
function update() refresh() end
function onIpc(event, payload)
    if event == "set" and (payload == "main off" or payload == "main on" or payload == "portrait off" or payload == "portrait on") then
        local role, mode = payload:match("^(%w+) (%w+)$")
        for _, display in ipairs(displays) do
            if display.role == role and display.enabled ~= (mode == "on") then change(display); return end
        end
    end
end
