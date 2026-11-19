--!nonstrict
-- Unified Umbriel workspace layout bar widget.
-- Configure `output` as a role ("main" / "portrait"), model substring ("G2721P" / "Sceptre L24"),
-- or connector name ("DP-2" / "DP-3").

local rawTarget = noctalia.getConfig("output")
local TARGET_SPEC = (type(rawTarget) == "string" and rawTarget ~= "") and rawTarget or "main"

local home = noctalia.getenv("HOME")
local function ctlCmd(...)
    if home and home ~= "" then
        return {"python3", home .. "/.local/bin/umbriel-ctl", ...}
    end
    return {"umbriel-ctl", ...}
end

local LAYOUTS = {
    dwindle   = { glyph = "layout-board-split", label = "Dwindle", title = "Dwindle Split" },
    scrolling = { glyph = "layout-columns",     label = "Scroll",  title = "Scrolling Strip" },
    master    = { glyph = "layout-board",       label = "Master",  title = "Master + Stack" },
    stacking  = { glyph = "layout-cards",       label = "Stack",   title = "Stacking / Floating" },
}

local ROLE_MODELS = {
    main = "G2721P",
    portrait = "Sceptre L24",
}

local resolvedOutput = nil
local lastWorkspaces = nil
local lastOutputs = nil
local busy = false

barWidget.setVisible(false)

local function matchesOutput(out, spec)
    if type(out) ~= "table" then return false end
    local name = tostring(out.name or "")
    if name == spec then return true end
    local haystack = tostring(out.make or "") .. " " .. tostring(out.model or "") .. " " .. tostring(out.description or "") .. " " .. tostring(out.config_name or "")
    local needle = ROLE_MODELS[spec]
    if needle and string.find(haystack, needle, 1, true) then
        return true
    end
    if spec == "portrait" then
        local t = tostring(out.transform or "")
        if string.find(t, "90", 1, true) or string.find(t, "270", 1, true) then
            return true
        end
    end
    return string.find(haystack, spec, 1, true) ~= nil
end

local function updateResolvedOutput()
    if type(lastOutputs) ~= "table" then return end
    for _, out in ipairs(lastOutputs) do
        if matchesOutput(out, TARGET_SPEC) then
            if out.enabled == false then
                resolvedOutput = nil
                return
            end
            resolvedOutput = tostring(out.name or "")
            return
        end
    end
    resolvedOutput = nil
end

local function renderWidget()
    if not resolvedOutput or resolvedOutput == "" or type(lastWorkspaces) ~= "table" then
        barWidget.setVisible(false)
        return
    end

    local target = nil
    for _, ws in ipairs(lastWorkspaces) do
        if type(ws) == "table" and ws.output == resolvedOutput and ws.active == true then
            target = ws
            break
        end
    end

    if not target then
        barWidget.setVisible(false)
        return
    end

    local wsName = tostring(target.name or target.index or "")
    local mode = tostring(target.layout or "scrolling")
    local info = LAYOUTS[mode] or { glyph = "layout-board-split", label = mode, title = mode }

    barWidget.setVisible(true)
    barWidget.setGlyph(info.glyph)
    barWidget.setText(info.label)
    barWidget.setColor(target.layout_override and "secondary" or "primary")
    barWidget.setTooltip(
        "Workspace " .. wsName .. " (" .. resolvedOutput .. "): " .. info.title
        .. "\nLeft-click: Cycle layout (Dwindle → Scroll → Master → Stack)"
        .. "\nRight-click: Reset workspace to configured default"
        .. "\nMiddle-click: Open Umbriel Control Center"
    )
end

local function onStreamLine(line)
    if not line or line == "" then return end
    local decoded = noctalia.json.decode(line)
    if type(decoded) ~= "table" then return end

    if decoded.event == "outputs" and type(decoded.data) == "table" then
        lastOutputs = decoded.data
        updateResolvedOutput()
        renderWidget()
    elseif decoded.event == "workspaces" and type(decoded.data) == "table" then
        lastWorkspaces = decoded.data
        if not resolvedOutput and not lastOutputs and TARGET_SPEC ~= "main" and TARGET_SPEC ~= "portrait" then
            resolvedOutput = TARGET_SPEC
        end
        renderWidget()
    end
end

if noctalia.commandExists("umbriel") then
    noctalia.runStream("umbriel subscribe outputs,workspaces 2>/dev/null", onStreamLine)
end

local function runLayout(mode)
    if busy or not resolvedOutput or resolvedOutput == "" then return end
    busy = true
    noctalia.runAsync(ctlCmd("layout", mode, "--output", resolvedOutput, "--quiet"), function(_res)
        busy = false
    end)
end

function onClick()
    runLayout("toggle")
end

function onRightClick()
    runLayout("reset")
end

function onMiddleClick()
    noctalia.togglePanel("desktop/umbriel-layout:controls")
end
