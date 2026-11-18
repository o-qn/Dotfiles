--!nonstrict
-- Fallback bar pill for empty Workspace 1 when [widget.workspaces] uses hide_when_empty = true.

local TARGET_OUTPUT = tostring(noctalia.getConfig("output") or "DP-2")

barWidget.setVisible(false)

local function applyWorkspaces(workspaces)
    if type(workspaces) ~= "table" or #workspaces == 0 then
        return
    end

    local ws1 = nil
    for _, ws in ipairs(workspaces) do
        if type(ws) == "table" and ws.output == TARGET_OUTPUT and tonumber(ws.index) == 1 then
            ws1 = ws
            break
        end
    end

    if not ws1 or ws1.active == true or ws1.occupied == true then
        barWidget.setVisible(false)
        return
    end

    barWidget.setVisible(true)
    barWidget.setText("1")
    barWidget.setColor("on_surface_variant")
    barWidget.setTooltip("Workspace 1 (" .. TARGET_OUTPUT .. "): Dwindle\nClick to switch to Workspace 1")
end

local function onStreamLine(line)
    if not line or line == "" then
        return
    end
    local decoded = noctalia.json.decode(line)
    if type(decoded) ~= "table" then
        return
    end
    if decoded.event == "workspaces" and type(decoded.data) == "table" then
        applyWorkspaces(decoded.data)
    elseif #decoded > 0 then
        applyWorkspaces(decoded)
    end
end

if noctalia.commandExists("umbriel") then
    noctalia.runAsync({"umbriel", "workspaces", "-j"}, function(result)
        if result and result.exitCode == 0 and result.stdout and result.stdout ~= "" then
            local data = noctalia.json.decode(result.stdout)
            if type(data) == "table" then
                applyWorkspaces(data)
            end
        end
    end)
    noctalia.runStream("umbriel subscribe workspaces 2>/dev/null", onStreamLine)
end

function onClick()
    noctalia.runAsync({"umbriel", "msg", "workspace-switch", "1", "--output", TARGET_OUTPUT})
end
