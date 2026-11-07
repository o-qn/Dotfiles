--!nonstrict
-- Umbriel Control Center panel inside Noctalia.
-- Shows clear explanations for each setting and highlights the currently active mode.

local home = noctalia.getenv("HOME") or "/home/qn"
local helper = home .. "/.local/bin/umbriel-effects"

local state = {
    workspace = "1",
    output = "DP-2",
    layout = "dwindle",
    layout_override = false,
    vrr_mode = "fullscreen",
    vrr_active = false,
    border_effect = "none",
    cursor_effect = "none",
}

local LAYOUT_DESC = {
    dwindle   = "Binary split tiling (Hyprland style) — only affects this workspace.",
    scrolling = "Infinite horizontal strip (Niri style) — only affects this workspace.",
    master    = "Main master window on the left + vertical stack on the right.",
    stacking  = "Floating windows with quick edge/corner snap regions.",
}

local VRR_DESC = {
    fullscreen = "Smart Auto: Fixed 200Hz on desktop; VRR turns on automatically in games & fullscreen.",
    always     = "Always On: Variable Refresh Rate forced active on the desktop and in games.",
    disabled   = "Disabled: Locked to fixed 200Hz refresh rate everywhere.",
}

local BORDER_DESC = {
    none  = "Solid Theme: Clean static border colored by your active Noctalia theme.",
    pulse = "Pulse Glow: Animated breathing light wave moving around your focused window.",
    audio = "Audio Reactive: Window border lights up and pulses to music/sound on your PC.",
}

local CURSOR_DESC = {
    none  = "Normal: Standard crisp desktop cursor with no GPU shader effect.",
    trail = "Comet Trail: Leaves a smooth motion trail behind the pointer when moving fast.",
    glow  = "Spotlight Glow: Renders a soft spotlight halo around the mouse pointer.",
}

local opened = false
local busy = false
local render

local function accept(res)
    if res and res.exitCode == 0 and res.stdout and res.stdout ~= "" then
        local decoded = noctalia.json.decode(res.stdout)
        if type(decoded) == "table" then
            state.workspace = tostring(decoded.workspace or state.workspace)
            state.output = tostring(decoded.output or state.output)
            state.layout = tostring(decoded.layout or state.layout)
            state.layout_override = decoded.layout_override == true
            state.vrr_mode = tostring(decoded.vrr_mode or state.vrr_mode)
            state.vrr_active = decoded.vrr_active == true
            state.border_effect = tostring(decoded.border_effect or state.border_effect)
            state.cursor_effect = tostring(decoded.cursor_effect or state.cursor_effect)
        end
    end
end

local function refresh()
    if not opened or busy then return end
    noctalia.runAsync({"python3", helper, "status"}, function(res)
        if not opened then return end
        accept(res)
        render()
    end)
end

local function runAction(category, mode)
    if category == "layout" then
        state.layout = mode
    elseif category == "vrr" then
        state.vrr_mode = mode
    elseif category == "border" then
        state.border_effect = mode
    elseif category == "cursor" then
        state.cursor_effect = mode
    end
    busy = true
    render()
    noctalia.runAsync({"python3", helper, category, mode}, function(res)
        busy = false
        if not opened then return end
        accept(res)
        render()
    end)
end

render = function()
    panel.render(ui.column({ gap = 10, align = "stretch", flexGrow = 1 }, {
        ui.row({ align = "center", gap = 8 }, {
            ui.label({ text = "Umbriel Control Center", fontSize = 18, fontWeight = "bold", flexGrow = 1 }),
            ui.button({
                text = "Shortcuts",
                variant = "ghost",
                onClick = function()
                    panel.close()
                    noctalia.runAsync({"umbriel", "msg", "cheatsheet-toggle"})
                end,
            }),
            ui.button({ glyph = "close", variant = "ghost", onClick = function() panel.close() end }),
        }),

        -- 1. Workspace Layout
        ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
            ui.row({ align = "center", gap = 8 }, {
                ui.label({
                    text = "Workspace " .. state.workspace .. " (" .. state.output .. ") Layout",
                    fontWeight = "bold",
                    flexGrow = 1,
                }),
                ui.label({
                    text = state.layout_override and "Custom for this workspace" or "Default (Dwindle)",
                    fontSize = 11,
                    color = state.layout_override and "primary" or "on_surface_variant",
                }),
            }),
            ui.label({
                text = LAYOUT_DESC[state.layout] or "",
                fontSize = 12,
                color = "on_surface_variant",
                maxLines = 2,
            }),
            ui.row({ gap = 6 }, {
                ui.button({
                    text = "Dwindle",
                    glyph = "layout-board-split",
                    variant = state.layout == "dwindle" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("layout", "dwindle") end,
                }),
                ui.button({
                    text = "Scroll",
                    glyph = "layout-columns",
                    variant = state.layout == "scrolling" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("layout", "scrolling") end,
                }),
                ui.button({
                    text = "Master",
                    glyph = "layout-board",
                    variant = state.layout == "master" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("layout", "master") end,
                }),
                ui.button({
                    text = "Stack",
                    glyph = "layout-cards",
                    variant = state.layout == "stacking" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("layout", "stacking") end,
                }),
            }),
        }),

        -- 2. VRR / Adaptive Sync
        ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
            ui.row({ align = "center", gap = 8 }, {
                ui.label({ text = "Variable Refresh Rate / VRR (DP-2)", fontWeight = "bold", flexGrow = 1 }),
                ui.label({
                    text = state.vrr_active and "Hardware VRR: Active" or "Hardware VRR: Standby (200Hz)",
                    fontSize = 11,
                    color = state.vrr_active and "primary" or "on_surface_variant",
                }),
            }),
            ui.label({
                text = VRR_DESC[state.vrr_mode] or "",
                fontSize = 12,
                color = "on_surface_variant",
                maxLines = 2,
            }),
            ui.row({ gap = 6 }, {
                ui.button({
                    text = "Smart Auto",
                    variant = state.vrr_mode == "fullscreen" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("vrr", "fullscreen") end,
                }),
                ui.button({
                    text = "Always On",
                    variant = state.vrr_mode == "always" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("vrr", "always") end,
                }),
                ui.button({
                    text = "Disabled",
                    variant = state.vrr_mode == "disabled" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("vrr", "disabled") end,
                }),
            }),
        }),

        -- 3. Window Border Style
        ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
            ui.label({ text = "Window Border Style", fontWeight = "bold" }),
            ui.label({
                text = BORDER_DESC[state.border_effect] or "",
                fontSize = 12,
                color = "on_surface_variant",
                maxLines = 2,
            }),
            ui.row({ gap = 6 }, {
                ui.button({
                    text = "Solid Theme",
                    variant = state.border_effect == "none" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("border", "none") end,
                }),
                ui.button({
                    text = "Pulse Glow",
                    variant = state.border_effect == "pulse" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("border", "pulse") end,
                }),
                ui.button({
                    text = "Audio Reactive",
                    variant = state.border_effect == "audio" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("border", "audio") end,
                }),
            }),
        }),

        -- 4. Mouse Cursor Effect
        ui.column({ gap = 6, padding = 12, radius = 12, fill = "surface_variant/0.6" }, {
            ui.label({ text = "Mouse Cursor Effect", fontWeight = "bold" }),
            ui.label({
                text = CURSOR_DESC[state.cursor_effect] or "",
                fontSize = 12,
                color = "on_surface_variant",
                maxLines = 2,
            }),
            ui.row({ gap = 6 }, {
                ui.button({
                    text = "Normal",
                    variant = state.cursor_effect == "none" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("cursor", "none") end,
                }),
                ui.button({
                    text = "Comet Trail",
                    variant = state.cursor_effect == "trail" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("cursor", "trail") end,
                }),
                ui.button({
                    text = "Spotlight Glow",
                    variant = state.cursor_effect == "glow" and "solid" or "outline",
                    flexGrow = 1,
                    onClick = function() runAction("cursor", "glow") end,
                }),
            }),
        }),
    }))
end

function onOpen(_context)
    opened, busy = true, false
    panel.setWantsSecondTicks(true)
    render()
    refresh()
end

function onClose()
    opened = false
    panel.setWantsSecondTicks(false)
end

function update()
    refresh()
end
