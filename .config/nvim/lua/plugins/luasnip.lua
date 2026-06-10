return {

    {

        "L3MON4D3/LuaSnip",

        dependencies = { "rafamadriz/friendly-snippets" },

        config = function()
            local ls = require("luasnip")

            ls.config.set_config({

                history = true,

                updateevents = "TextChanged,TextChangedI",

                delete_check_events = "TextChanged",
            })

            require("luasnip.loaders.from_lua").load({

                paths = { vim.fn.stdpath("config") .. "/snippets" },
            })

            require("luasnip.loaders.from_vscode").lazy_load({ exclude = { "csharp" } })

            ls.filetype_extend("cs", { "csharp" })

            vim.api.nvim_create_autocmd("ModeChanged", {

                pattern = "*:s",

                callback = function()
                    local opts = { buffer = true, silent = true }

                    local chars = { "d", "i", "c", "a", "s", "D", "I", "A", "C" }

                    for _, key in ipairs(chars) do
                        vim.keymap.set("s", key, "<BS>i" .. key, opts)
                    end

                    vim.keymap.set("s", "<BS>", "<C-O>c", opts)
                end,
            })
        end,
    },
}
