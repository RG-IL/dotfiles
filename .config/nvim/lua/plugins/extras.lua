return {
    {
        "folke/tokyonight.nvim",
        enabled = false,
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {},
    },
    { "ThePrimeagen/vim-be-good" },
    {
        "folke/noice.nvim",
        opts = function(_, opts)
            opts.presets = opts.presets or {}
            opts.presets.command_palette = false

            opts.views = opts.views or {}

            opts.views.hover = {
                position = {
                    row = 3,
                    col = 0,
                },
                border = {
                    style = "rounded",
                },
                win_options = {
                    winhighlight = "Normal:NoiceHoverNormal,FloatBorder:NoiceHoverBorder",
                },
            }

            return opts
        end,
    },
    {
        "akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
            if (vim.g.colors_name or ""):find("catppuccin") then
                opts.highlights = require("catppuccin.special.bufferline").get_theme()
            end
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            opts.options = opts.options or {}
            opts.options.theme = require("raphael").lualine

            opts.options.section_separators = { left = "", right = "" }
            opts.options.component_separators = { left = "", right = "" }

            if opts.sections and opts.sections.lualine_a and opts.sections.lualine_a[1] then
                local comp = opts.sections.lualine_a[1]
                if type(comp) == "string" then
                    opts.sections.lualine_a[1] =
                        { comp, color = { fg = "#5C3A21" }, separator = { left = "", right = "" } }
                elseif type(comp) == "table" then
                    comp.color = { fg = "#5C3A21" }
                    comp.separator = { left = "", right = "" }
                end
            end

            if opts.sections and opts.sections.lualine_z then
                opts.sections.lualine_z = {
                    {
                        function()
                            return os.date("%R")
                        end,
                        color = { bg = "#F2CDCD", fg = "#5C3A21" },
                        separator = { left = "", right = "" },
                    },
                }
            end

            if opts.sections and opts.sections.lualine_y then
                for i, comp in ipairs(opts.sections.lualine_y) do
                    if type(comp) == "string" then
                        opts.sections.lualine_y[i] = { comp, color = { bg = "#EB9FAC", fg = "#5C3A21" } }
                    elseif type(comp) == "table" then
                        comp.color = { bg = "#EB9FAC", fg = "#5C3A21" }
                    end
                end
            end

            opts.sections.lualine_x = opts.sections.lualine_x or {}
            table.insert(opts.sections.lualine_x, 3, function()
                return require("opencode").statusline() .. " "
            end)
        end,
    },
    {
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = {},
    },
    {
        "sphamba/smear-cursor.nvim",
        opts = {
            stiffness = 0.67, -- 0.6      [0, 1]
            trailing_stiffness = 0.3, -- 0.45     [0, 1]
            stiffness_insert_mode = 1, -- 0.5      [0, 1]
            trailing_stiffness_insert_mode = 1, -- 0.5      [0, 1]
            damping = 0.67, -- 0.85     [0, 1]
            damping_insert_mode = 1,
            distance_stop_animating = 0.5,
            legacy_computing_symbols_support = true,
        },
    },
    {
        "eandrju/cellular-automaton.nvim",
    },

    {
        "kdheepak/lazygit.nvim",
        keys = {
            { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit (Clean Config)" },
        },
        config = function()
            vim.g.lazygit_config = 0
        end,
    },
}
