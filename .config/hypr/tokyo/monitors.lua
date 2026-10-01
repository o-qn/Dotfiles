-- Match hardware descriptions so reconnecting cables does not swap the displays.
-- Your original layout with DP-2 / DP-3 swapped: portrait LEFT, main RIGHT.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.monitor({
    output = "desc:HKC OVERSEAS LIMITED G2721P 0000000000001",
    mode = "2560x1440@200Hz", position = "0x0", scale = 1.25, vrr = 2,
})
hl.monitor({
    output = "desc:Sceptre Tech Inc Sceptre L24 0000000000000",
    mode = "1920x1080@144Hz", position = "-1080x-384", scale = 1, transform = 1, vrr = 2,
})
-- Center the portrait display beside the 2048x1152 logical main display.
hl.workspace_rule({ workspace = "1", monitor = "desc:HKC OVERSEAS LIMITED G2721P 0000000000001", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "desc:Sceptre Tech Inc Sceptre L24 0000000000000", default = true, persistent = true })
-- All other workspaces are created on demand on the current monitor.
