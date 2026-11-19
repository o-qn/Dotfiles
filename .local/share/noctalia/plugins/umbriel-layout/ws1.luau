--!nonstrict
-- Fallback bar pill for empty Workspace 1 when [widget.workspaces] uses hide_when_empty = true.
-- Supports role ("main" / "portrait"), model substring, or connector name via `output` setting.

local rawTarget = noctalia.getConfig("output")
local TARGET_SPEC = (type(rawTarget) == "string" and rawTarget ~= "") and rawTarget or "main"

local ROLE_MODELS = {
    main = "G2721P",
    portrait = "Sceptre L24",
}

local resolvedOutput = nil
local lastOutputs = nil
local lastWorkspaces = nil

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

    local ws1 = nil
    for _, ws in ipairs(lastWorkspaces) do
        if type(ws) == "table" and ws.output == resolvedOutput and tonumber(ws.index) == 1 then
            ws1 = ws
            break
        end
    end

    if not ws1 or ws1.active == true or ws1.occupied == true then
        barWidget.setVisible(false)
        return
    end

    local layoutLabel = tostring(ws1.layout or "dwindle")
    layoutLabel = string.upper(string.sub(layoutLabel, 1, 1)) .. string.sub(layoutLabel, 2)

    barWidget.setVisible(true)
    barWidget.setText("1")
    barWidget.setColor("on_surface_variant")
    barWidget.setTooltip(
        "Workspace 1 (" .. resolvedOutput .. "): " .. layoutLabel
        .. "\nClick to switch to Workspace 1"
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

function onClick()
    if not resolvedOutput or resolvedOutput == "" then return end
    noctalia.runAsync({"umbriel", "msg", "workspace-switch", "1", "--output", resolvedOutput})
end
