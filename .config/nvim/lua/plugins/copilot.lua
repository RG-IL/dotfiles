return {
    {
        "zbirenbaum/copilot.lua",
        -- LazyVim's copilot extra disables copilot's own ghost text when
        -- blink.cmp is the completion engine (vim.g.ai_cmp), routing copilot
        -- suggestions into the blink menu instead. We want supermaven-style
        -- inline suggestions, so turn ghost text back on. While the blink
        -- menu is open the ghost text hides, so nothing is shown twice.
        opts = function(_, opts)
            opts.suggestion = vim.tbl_deep_extend("force", opts.suggestion or {}, {
                enabled = true,
                auto_trigger = true,
                hide_during_completion = true,
                keymap = {
                    -- falls through to blink when no suggestion is visible
                    accept = "<Tab>",
                    dismiss = "<C-]>",
                },
            })
            return opts
        end,
    },
}
