return {
    {
        "saghen/blink.cmp",
        -- stay on stable v1: main is v2-pre and needs saghen/blink.lib (LazyVim 16.x doesn't manage it yet)
        version = "1.*",
        dependencies = { "L3MON4D3/LuaSnip" },
        opts = {
            snippets = {
                preset = "luasnip",
            },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
            keymap = {
                preset = "default",
                ["<C-f>"] = { "snippet_forward", "fallback" },
                ["<C-b>"] = { "snippet_backward", "fallback" },
            },
            -- Rounded borders with custom highlights
            completion = {
                menu = {
                    border = "rounded",
                    winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
                },
                documentation = {
                    window = {
                        border = "rounded",
                        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocSelection,Search:None",
                    },
                },
            },
        },
    },
}
