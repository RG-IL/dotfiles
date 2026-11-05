local vars = require("variables")

hl.config({
    general = {
        layout          = "dwindle",

        allow_tearing   = false, -- Allows `immediate` window rule to work

        gaps_workspaces = vars.workspaceGaps,
        gaps_in         = vars.windowGapsIn,
        gaps_out        = vars.windowGapsOut,
        border_size     = vars.windowBorderSize,

        col             = {
            active_border   = vars.activeWindowBorderColour,
            inactive_border = vars.inactiveWindowBorderColour,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },

    -- AutoHDR flips the monitor's scanout format when HDR content appears,
    -- and the TS2400 drops its HDMI link on every flip. We don't want HDR.
    render = {
        cm_auto_hdr = 0,
    },

    scrolling = {
        fullscreen_on_one_column = true,
        focus_fit_method         = 1,
        column_width             = 0.5,
        follow_focus             = true,
        follow_min_visible       = 0.0,
        explicit_column_widths   = "0.35, 0.5, 0.65, 1.0",
    },
})
