--!nonstrict
-- Event-driven Umbriel Control Center panel inside Noctalia.
-- Dual-monitor Layout, VRR, HDR/SDR White, Tearing, Shaders, Animations, and Game Watcher controls.

local home = noctalia.getenv("HOME")
local function ctlCmd(...)
    if home and home ~= "" then
        return {"python3", home .. "/.local/bin/umbriel-ctl", ...}
    end
    return {"umbriel-ctl", ...}
end

local state = {
    selected_output = "",
    workspace = "1",
    output = "",
    output_label = "Main",
    refresh_hz = 0,
    layout = "dwindle",
    layout_default = "dwindle",
    layout_override = false,
    vrr_mode = "fullscreen",
    vrr_active = false,
    hdr_supported = false,
    hdr_mode = "off",
    hdr_active = false,
    sdr_white = 203.0,
    tearing_enabled = false,
    bit_depth = 8,
    bit_depth_active = false,
    direct_scanout_active = false,
    direct_scanout_reason = "composited",
    border_effect = "none",
    cursor_effect = "none",
    screen_effect = "none",
    window_effect = "none",
    anim_move = "none",
    anim_workspace = "slide",
    game_auto_suspend_effects = true,
    game_auto_dnd = false,
    scratchpad_hidden = 0,
    submap = nil,
    outputs = {},
}

local LAYOUT_DESC = {
    dwindle   = "Binary split tiling (Hyprland style) — applies only to this workspace.",
    scrolling = "Infinite horizontal strip (Niri style) — applies only to this workspace.",
    master    = "Main master window + vertical stack — applies only to this workspace.",
    stacking  = "Floating windows with snap regions (Mod+Alt+W) — applies only to this workspace.",
}

local BORDER_DESC = {
    none  = "Solid Theme: Static Noctalia theme border (zero shader overhead).",
    pulse = "Pulse Glow: Animated breathing glow around the focused window.",
    audio = "Audio Reactive: Window border reacts live to system audio.",
}

local CURSOR_DESC = {
    none         = "Normal: Crisp hardware cursor with zero GPU shader cost.",
    trail        = "Comet Trail: Short 300ms motion trail behind pointer movement.",
    ["trail-path"] = "Ribbon Trail: Smooth 2-second curved color ribbon trail.",
    glow         = "Spotlight Glow: Soft theme-colored halo around the pointer.",
}

local SDR_WHITE_PRESETS = { 203, 260, 320, 400 }

local opened = false
local busy = false
local querying = false
local userSelectedOutput = nil
local errorMessage = ""
local reqSeq = 0
local render

local function capitalize(s)
    if type(s) ~= "string" or s == "" then return "" end
    return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
end

local function accept(res)
    if not res then
        errorMessage = "No response from umbriel-ctl"
        return false
    end
    local decoded, err = noctalia.json.decode(res.stdout or "")
    if type(decoded) ~= "table" then
        errorMessage = (res.stderr and res.stderr ~= "" and res.stderr) or err or "Invalid response from umbriel-ctl"
        return false
    end
    if decoded.error then
        errorMessage = tostring(decoded.error)
        return false
    end
    if res.exitCode ~= 0 then
        errorMessage = (res.stderr and res.stderr ~= "" and res.stderr) or "Command failed"
        return false
    end

    errorMessage = ""
    state.selected_output = tostring(decoded.selected_output or decoded.output or state.selected_output)
    state.workspace = tostring(decoded.workspace or state.workspace)
    state.output = tostring(decoded.output or state.output)
    state.output_label = tostring(decoded.output_label or state.output_label)
    state.refresh_hz = tonumber(decoded.refresh_hz) or state.refresh_hz
    state.layout = tostring(decoded.layout or state.layout)
    state.layout_default = tostring(decoded.layout_default or state.layout_default)
    state.layout_override = decoded.layout_override == true
    state.vrr_mode = tostring(decoded.vrr_mode or state.vrr_mode)
    state.vrr_active = decoded.vrr_active == true
    state.hdr_supported = decoded.hdr_supported == true
    state.hdr_mode = tostring(decoded.hdr_mode or state.hdr_mode)
    state.hdr_active = decoded.hdr_active == true
    state.sdr_white = tonumber(decoded.sdr_white) or state.sdr_white
    state.tearing_enabled = decoded.tearing_enabled == true
    state.bit_depth = tonumber(decoded.bit_depth) or state.bit_depth
    state.bit_depth_active = decoded.bit_depth_active == true
    state.direct_scanout_active = decoded.direct_scanout_active == true
    state.direct_scanout_reason = tostring(decoded.direct_scanout_reason or "composited")
    state.border_effect = tostring(decoded.border_effect or "none")
    state.cursor_effect = tostring(decoded.cursor_effect or "none")
    state.screen_effect = tostring(decoded.screen_effect or "none")
    state.window_effect = tostring(decoded.window_effect or "none")
    state.anim_move = tostring(decoded.anim_move or "none")
    state.anim_workspace = tostring(decoded.anim_workspace or "slide")
    state.game_auto_suspend_effects = decoded.game_auto_suspend_effects == true
    state.game_auto_dnd = decoded.game_auto_dnd == true
    state.scratchpad_hidden = tonumber(decoded.scratchpad_hidden) or 0
    state.submap = type(decoded.submap) == "string" and decoded.submap or nil
    if type(decoded.outputs) == "table" then
        state.outputs = decoded.outputs
    end
    return true
end

local function refresh()
    if not opened or busy or querying then return end
    querying = true
    reqSeq = reqSeq + 1
    local mySeq = reqSeq

    local cmd = userSelectedOutput and ctlCmd("status", "--output", userSelectedOutput) or ctlCmd("status")
    noctalia.runAsync(cmd, function(res)
        querying = false
        if not opened or busy or mySeq ~= reqSeq then return end
        accept(res)
        render()
    end)
end

local function runCtl(...)
    if busy then return end
    busy = true
    errorMessage = ""
    reqSeq = reqSeq + 1
    local mySeq = reqSeq
    render()

    local args = { ... }
    table.insert(args, "--json")
    table.insert(args, "--quiet")
    noctalia.runAsync(ctlCmd(table.unpack(args)), function(res)
        busy = false
        if not opened or mySeq ~= reqSeq then return end
        accept(res)
        render()
    end)
end

local function selectMonitor(connector)
    if busy then return end
    userSelectedOutput = connector
    refresh()
end

local function vrrBadgeText()
    local hz = state.refresh_hz > 0 and (tostring(state.refresh_hz) .. "Hz") or "Fixed Hz"
    if state.vrr_active then
        return "Hardware VRR: Active"
    elseif state.vrr_mode == "disabled" then
        return "Hardware VRR: Off (" .. hz .. ")"
    else
        return "Hardware VRR: Standby (" .. hz .. ")"
    end
end

local function vrrDescription()
    local hz = state.refresh_hz > 0 and (tostring(state.refresh_hz) .. "Hz") or "fixed refresh"
    if state.vrr_mode == "fullscreen" then
        return "Smart Auto: Fixed " .. hz .. " on desktop (low idle watts); VRR only in fullscreen."
    elseif state.vrr_mode == "always" then
        return "Always On: Adaptive sync forced active everywhere."
    else
        return "Disabled: Locked to fixed " .. hz .. " everywhere (lowest GPU idle power)."
    end
end

local function closestSdrPreset()
    local best = 203
    local bestDiff = 9999
    for _, p in ipairs(SDR_WHITE_PRESETS) do
        local diff = math.abs(state.sdr_white - p)
        if diff < bestDiff then
            bestDiff = diff
            best = p
        end
    end
    return best
end

render = function()
    local targetOut = state.output ~= "" and state.output or (userSelectedOutput or "")
    local enabled = not busy

    -- Build dynamic monitor selector row
    local monitorButtons = {}
    for _, o in ipairs(state.outputs) do
        if type(o) == "table" and o.connector and o.connector ~= "" then
            local shortRes = (o.height and o.height > 0) and (tostring(o.height) .. "p") or ""
            local hzText = (o.refresh_hz and o.refresh_hz > 0) and (tostring(o.refresh_hz) .. "Hz") or ""
            local meta = (shortRes ~= "" and hzText ~= "") and (" " .. shortRes .. "·" .. hzText) or ""
            local isSel = (o.connector == targetOut)
            local conn = tostring(o.connector)
            table.insert(monitorButtons, ui.button({
                text = tostring(o.label or conn) .. " · " .. conn .. meta .. (o.enabled == false and " (Off)" or ""),
                glyph = "device-desktop",
                variant = isSel and "primary" or "outline",
                enabled = enabled and o.enabled ~= false,
                flexGrow = 1,
                onClick = function() selectMonitor(conn) end,
            }))
        end
    end

    local scanoutText = state.direct_scanout_active and "Direct Scanout" or ("Composited")
    local depthText = tostring(state.bit_depth) .. "-bit" .. (state.bit_depth_active and " active" or "")
    local hdrSummary = state.hdr_supported
        and ("HDR: " .. (state.hdr_active and "Active" or capitalize(state.hdr_mode)))
        or "HDR: SDR Panel"
    local telemetryLine = depthText
        .. "  ·  " .. scanoutText
        .. "  ·  " .. hdrSummary
        .. "  ·  Tearing: " .. (state.tearing_enabled and "Allow" or "Off")

    local cards = {}

    if #monitorButtons > 0 then
        table.insert(cards, ui.column({ gap = 6, padding = 10, radius = 12, fill = "surface_variant/0.45" }, {
            ui.row({ gap = 6 }, monitorButtons),
            ui.label({ text = telemetryLine, fontSize = 11, color = "on_surface_variant", maxLines = 2 }),
        }))
    end

    if errorMessage ~= "" then
        table.insert(cards, ui.label({ text = errorMessage, fontSize = 12, color = "error", maxLines = 2 }))
    end

    -- 1. Workspace Layout (targeted to selected output)
    local layoutHeaderItems = {
        ui.label({
            text = "WS " .. state.workspace .. " (" .. state.output_label .. " · " .. targetOut .. ") Layout",
            fontWeight = "bold",
            flexGrow = 1,
        }),
        ui.label({
            text = state.layout_override
                and "Custom override"
                or ("Default (" .. capitalize(state.layout_default) .. ")"),
            fontSize = 11,
            color = state.layout_override and "primary" or "on_surface_variant",
        }),
    }
    if state.layout_override then
        table.insert(layoutHeaderItems, ui.button({
            text = "Reset",
            variant = "ghost",
            enabled = enabled,
            onClick = function() runCtl("layout", "reset", "--output", targetOut) end,
        }))
    end

    table.insert(cards, ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
        ui.row({ align = "center", gap = 6 }, layoutHeaderItems),
        ui.label({ text = LAYOUT_DESC[state.layout] or "", fontSize = 12, color = "on_surface_variant", maxLines = 2 }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Dwindle",
                glyph = "layout-board-split",
                variant = state.layout == "dwindle" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("layout", "dwindle", "--output", targetOut) end,
            }),
            ui.button({
                text = "Scroll",
                glyph = "layout-columns",
                variant = state.layout == "scrolling" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("layout", "scrolling", "--output", targetOut) end,
            }),
            ui.button({
                text = "Master",
                glyph = "layout-board",
                variant = state.layout == "master" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("layout", "master", "--output", targetOut) end,
            }),
            ui.button({
                text = "Stack",
                glyph = "layout-cards",
                variant = state.layout == "stacking" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("layout", "stacking", "--output", targetOut) end,
            }),
        }),
    }))

    -- 2. VRR / Adaptive Sync (per selected output, zero-reload)
    table.insert(cards, ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
        ui.row({ align = "center", gap = 8 }, {
            ui.label({ text = "VRR (" .. state.output_label .. " · " .. targetOut .. ")", fontWeight = "bold", flexGrow = 1 }),
            ui.label({
                text = vrrBadgeText(),
                fontSize = 11,
                color = state.vrr_active and "primary" or "on_surface_variant",
            }),
        }),
        ui.label({ text = vrrDescription(), fontSize = 12, color = "on_surface_variant", maxLines = 2 }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Smart Auto",
                variant = state.vrr_mode == "fullscreen" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("vrr", "fullscreen", "--output", targetOut) end,
            }),
            ui.button({
                text = "Always On",
                variant = state.vrr_mode == "always" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("vrr", "always", "--output", targetOut) end,
            }),
            ui.button({
                text = "Disabled",
                variant = state.vrr_mode == "disabled" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("vrr", "disabled", "--output", targetOut) end,
            }),
        }),
    }))

    -- 3. HDR, SDR White & Tearing
    local displayRows = {}
    if state.hdr_supported then
        table.insert(displayRows, ui.row({ align = "center", gap = 8 }, {
            ui.label({ text = "HDR & Color (" .. targetOut .. ")", fontWeight = "bold", flexGrow = 1 }),
            ui.label({
                text = state.hdr_active and "BT.2020 PQ Active" or ("Mode: " .. capitalize(state.hdr_mode)),
                fontSize = 11,
                color = state.hdr_active and "primary" or "on_surface_variant",
            }),
        }))
        table.insert(displayRows, ui.row({ gap = 6 }, {
            ui.button({
                text = "Off",
                variant = state.hdr_mode == "off" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("hdr", "off", "--output", targetOut) end,
            }),
            ui.button({
                text = "Auto",
                variant = state.hdr_mode == "auto" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("hdr", "auto", "--output", targetOut) end,
            }),
            ui.button({
                text = "Fullscreen",
                variant = state.hdr_mode == "fullscreen" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("hdr", "fullscreen", "--output", targetOut) end,
            }),
            ui.button({
                text = "On",
                variant = state.hdr_mode == "on" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("hdr", "on", "--output", targetOut) end,
            }),
        }))

        local activePreset = closestSdrPreset()
        local sdrBtns = {}
        for _, nits in ipairs(SDR_WHITE_PRESETS) do
            table.insert(sdrBtns, ui.button({
                text = tostring(nits) .. " nits",
                variant = (activePreset == nits) and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("sdr-white", tostring(nits), "--output", targetOut) end,
            }))
        end
        table.insert(displayRows, ui.label({
            text = "SDR Reference White (current: " .. tostring(math.floor(state.sdr_white + 0.5)) .. " nits)",
            fontSize = 11,
            color = "on_surface_variant",
        }))
        table.insert(displayRows, ui.row({ gap = 6 }, sdrBtns))
    else
        table.insert(displayRows, ui.label({ text = "Display Presentation (" .. targetOut .. ")", fontWeight = "bold" }))
    end

    table.insert(displayRows, ui.row({ gap = 6 }, {
        ui.button({
            text = "Tearing: " .. (state.tearing_enabled and "Allowed (Fullscreen)" or "Off (VSync)"),
            variant = state.tearing_enabled and "primary" or "outline",
            enabled = enabled,
            flexGrow = 1,
            onClick = function() runCtl("tearing", "toggle", "--output", targetOut) end,
        }),
    }))
    table.insert(cards, ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, displayRows))

    -- 4. Quick Presets & Fullscreen Game Watcher
    table.insert(cards, ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
        ui.label({ text = "Presets & Game Watcher", fontWeight = "bold" }),
        ui.label({
            text = "Presets adjust shaders & animations only — your VRR toggle is never overwritten.",
            fontSize = 11,
            color = "on_surface_variant",
            maxLines = 2,
        }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Clean / Gaming",
                variant = (state.border_effect == "none" and state.cursor_effect == "none" and state.screen_effect == "none") and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("profile", "gaming", "--output", targetOut) end,
            }),
            ui.button({
                text = "Eye Candy",
                variant = (state.border_effect == "pulse" and state.cursor_effect == "trail") and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("profile", "candy", "--output", targetOut) end,
            }),
        }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Game Pause Shaders: " .. (state.game_auto_suspend_effects and "On" or "Off"),
                variant = state.game_auto_suspend_effects and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("watcher-opt", "suspend-effects", "toggle", "--output", targetOut) end,
            }),
            ui.button({
                text = "Game Auto-DND: " .. (state.game_auto_dnd and "On" or "Off"),
                variant = state.game_auto_dnd and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("watcher-opt", "auto-dnd", "toggle", "--output", targetOut) end,
            }),
        }),
    }))

    -- 5. Window Border Style
    table.insert(cards, ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
        ui.label({ text = "Window Border Style", fontWeight = "bold" }),
        ui.label({ text = BORDER_DESC[state.border_effect] or "", fontSize = 12, color = "on_surface_variant", maxLines = 2 }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Solid Theme",
                variant = state.border_effect == "none" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("border", "none", "--output", targetOut) end,
            }),
            ui.button({
                text = "Pulse Glow",
                variant = state.border_effect == "pulse" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("border", "pulse", "--output", targetOut) end,
            }),
            ui.button({
                text = "Audio Reactive",
                variant = state.border_effect == "audio" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("border", "audio", "--output", targetOut) end,
            }),
        }),
    }))

    -- 6. Mouse Cursor Effect
    table.insert(cards, ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
        ui.label({ text = "Mouse Cursor Effect", fontWeight = "bold" }),
        ui.label({ text = CURSOR_DESC[state.cursor_effect] or "", fontSize = 12, color = "on_surface_variant", maxLines = 2 }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Normal",
                variant = state.cursor_effect == "none" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("cursor", "none", "--output", targetOut) end,
            }),
            ui.button({
                text = "Comet",
                variant = state.cursor_effect == "trail" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("cursor", "trail", "--output", targetOut) end,
            }),
            ui.button({
                text = "Ribbon",
                variant = state.cursor_effect == "trail-path" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("cursor", "trail-path", "--output", targetOut) end,
            }),
            ui.button({
                text = "Glow",
                variant = state.cursor_effect == "glow" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("cursor", "glow", "--output", targetOut) end,
            }),
        }),
    }))

    -- 7. Extra Shaders & Animations
    table.insert(cards, ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
        ui.label({ text = "Extra Shaders & Animations", fontWeight = "bold" }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Vignette: " .. (state.screen_effect == "vignette" and "On" or "Off"),
                variant = state.screen_effect == "vignette" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("screen", "toggle", "--output", targetOut) end,
            }),
            ui.button({
                text = "Scanlines (Window): " .. (state.window_effect == "scanlines" and "On" or "Off"),
                variant = state.window_effect == "scanlines" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("window", "toggle", "--output", targetOut) end,
            }),
        }),
        ui.row({ gap = 6 }, {
            ui.button({
                text = "Move Squash: " .. (state.anim_move == "squash" and "On" or "Off"),
                variant = state.anim_move == "squash" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("anim-move", "toggle", "--output", targetOut) end,
            }),
            ui.button({
                text = "WS Transition: " .. (state.anim_workspace == "wipe" and "Wipe" or "Slide"),
                variant = state.anim_workspace == "wipe" and "primary" or "outline",
                enabled = enabled,
                flexGrow = 1,
                onClick = function() runCtl("anim-workspace", "toggle", "--output", targetOut) end,
            }),
        }),
    }))

    panel.render(ui.column({ gap = 10, align = "stretch", flexGrow = 1 }, {
        ui.row({ align = "center", gap = 8 }, {
            ui.label({ text = "Umbriel Control Center", fontSize = 18, fontWeight = "bold", flexGrow = 1 }),
            ui.button({
                text = "Search",
                variant = "ghost",
                onClick = function()
                    panel.close()
                    if home and home ~= "" then
                        noctalia.runAsync({home .. "/.local/bin/desktop-shortcuts", "umbriel"})
                    else
                        noctalia.runAsync({"desktop-shortcuts", "umbriel"})
                    end
                end,
            }),
            ui.button({
                text = "Cheatsheet",
                variant = "ghost",
                onClick = function()
                    panel.close()
                    noctalia.runAsync({"umbriel", "msg", "cheatsheet-toggle"})
                end,
            }),
            ui.button({ glyph = "close", variant = "ghost", onClick = function() panel.close() end }),
        }),
        ui.scroll({ flexGrow = 1, gap = 10 }, cards),
    }))
end

local function onStreamLine(line)
    if not opened or busy or querying or not line or line == "" then
        return
    end
    refresh()
end

if noctalia.commandExists("umbriel") then
    noctalia.runStream("umbriel subscribe workspaces,outputs,submap,screencast 2>/dev/null", onStreamLine)
end

function onOpen(_context)
    opened = true
    busy = false
    querying = false
    userSelectedOutput = nil
    errorMessage = ""
    render()
    refresh()
end

function onClose()
    opened = false
end
