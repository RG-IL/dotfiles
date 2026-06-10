return {
    {
        "saghen/blink.cmp",
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
            -- הגדרת מסגרת עגולה וקישור ל-Highlights מותאמים
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
