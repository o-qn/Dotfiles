--!nonstrict
-- Dedicated Umbriel workspace layout indicator for Main Monitor (DP-2).

local TARGET_OUTPUT = "DP-2"
local helper = (noctalia.getenv("HOME") or "/home/qn") .. "/.local/bin/umbriel-layout"

local LAYOUTS = {
    dwindle   = { glyph = "layout-board-split", label = "Dwindle", title = "Dwindle Split" },
    scrolling = { glyph = "layout-columns", label = "Scroll", title = "Scrolling Strip" },
    master    = { glyph = "layout-board", label = "Master", title = "Master + Stack" },
    stacking  = { glyph = "layout-cards", label = "Stack", title = "Stacking / Floating" },
}

barWidget.setVisible(false)

local function applyWorkspaces(workspaces)
    if type(workspaces) ~= "table" or #workspaces == 0 then
        return
    end

    local target = nil
    for _, ws in ipairs(workspaces) do
        if type(ws) == "table" and ws.output == TARGET_OUTPUT and ws.active == true then
            target = ws
            break
        end
    end

    if not target then
        return
    end

    local mode = tostring(target.layout or "dwindle")
    local info = LAYOUTS[mode] or { glyph = "layout-board-split", label = mode, title = mode }

    barWidget.setVisible(true)
    barWidget.setGlyph(info.glyph)
    barWidget.setText(info.label)
    barWidget.setColor(target.layout_override and "secondary" or "primary")
    barWidget.setTooltip(
        "Workspace " .. tostring(target.name or target.index or "") .. " (DP-2): " .. info.title
        .. "\nLeft-click: Cycle this workspace's layout (Dwindle → Scroll → Master → Stack)"
        .. "\nRight-click: Reset this workspace to Dwindle"
        .. "\nMiddle-click: Open Umbriel Control Panel"
    )
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
    noctalia.runAsync({"python3", helper, "toggle", "--output", TARGET_OUTPUT})
end

function onRightClick()
    noctalia.runAsync({"python3", helper, "dwindle", "--output", TARGET_OUTPUT})
end

function onMiddleClick()
    noctalia.togglePanel("desktop/umbriel-layout:controls")
end
