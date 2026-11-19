--!nonstrict
-- Auto-hiding status pill for active Umbriel submaps, live screencasts, and hidden scratchpads.
-- Stays completely hidden during normal desktop use.

local activeSubmap = nil
local screencastActive = false
local screencastKind = ""
local hiddenScratchpads = 0

barWidget.setVisible(false)

local function renderWidget()
    if activeSubmap and activeSubmap ~= "" then
        barWidget.setVisible(true)
        barWidget.setGlyph("keyboard")
        barWidget.setText(string.upper(activeSubmap))
        barWidget.setColor("warning")
        barWidget.setTooltip(
            "Active Submap: " .. activeSubmap
            .. "\nPress Escape / Return or click to exit submap"
        )
        return
    end

    if screencastActive then
        barWidget.setVisible(true)
        barWidget.setGlyph("cast")
        barWidget.setText("CAST")
        barWidget.setColor("error")
        barWidget.setTooltip(
            "Screencast active (" .. (screencastKind ~= "" and screencastKind or "live") .. ")"
            .. "\nLeft-click: Pause / clear screencast"
            .. "\nRight-click: Enter Cast submap (Mod+Alt+S)"
        )
        return
    end

    if hiddenScratchpads > 0 then
        barWidget.setVisible(true)
        barWidget.setGlyph("layout-cards")
        barWidget.setText(tostring(hiddenScratchpads))
        barWidget.setColor("secondary")
        barWidget.setTooltip(
            tostring(hiddenScratchpads) .. " hidden scratchpad window" .. (hiddenScratchpads == 1 and "" or "s")
            .. "\nLeft-click: Toggle quick scratchpad (Mod+')"
            .. "\nRight-click: Toggle terminal scratchpad (Mod+;)"
        )
        return
    end

    barWidget.setVisible(false)
end

local function onStreamLine(line)
    if not line or line == "" then return end
    local decoded = noctalia.json.decode(line)
    if type(decoded) ~= "table" then return end

    if decoded.event == "submap" then
        if type(decoded.data) == "string" and decoded.data ~= "" then
            activeSubmap = decoded.data
        else
            activeSubmap = nil
        end
        renderWidget()
    elseif decoded.event == "screencast" then
        if type(decoded.data) == "table" then
            local kind = tostring(decoded.data.kind or "")
            screencastKind = kind
            screencastActive = (kind ~= "" and kind ~= "clear")
        else
            screencastActive = false
            screencastKind = ""
        end
        renderWidget()
    elseif decoded.event == "windows" and type(decoded.data) == "table" then
        local count = 0
        for _, win in ipairs(decoded.data) do
            if type(win) == "table" and type(win.scratchpad) == "string" and win.scratchpad ~= "" and win.visible == false then
                count = count + 1
            end
        end
        hiddenScratchpads = count
        renderWidget()
    end
end

if noctalia.commandExists("umbriel") then
    noctalia.runStream("umbriel subscribe submap,screencast,windows 2>/dev/null", onStreamLine)
end

function onClick()
    if activeSubmap and activeSubmap ~= "" then
        noctalia.runAsync({"umbriel", "msg", "submap", "reset"})
    elseif screencastActive then
        noctalia.runAsync({"umbriel", "msg", "screencast-clear"})
    elseif hiddenScratchpads > 0 then
        noctalia.runAsync({"umbriel", "msg", "scratchpad-toggle", "quick"})
    end
end

function onRightClick()
    if screencastActive then
        noctalia.runAsync({"umbriel", "msg", "submap", "cast"})
    elseif hiddenScratchpads > 0 then
        noctalia.runAsync({"umbriel", "msg", "scratchpad-toggle", "term"})
    end
end
