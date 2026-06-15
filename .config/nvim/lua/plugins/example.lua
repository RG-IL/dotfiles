return {
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
            stiffness = 0.6, -- 0.6      [0, 1]
            trailing_stiffness = 0.3, -- 0.45     [0, 1]
            stiffness_insert_mode = 1, -- 0.5      [0, 1]
            trailing_stiffness_insert_mode = 1, -- 0.5      [0, 1]
            damping = 0.67, -- 0.85     [0, 1]
            damping_insert_mode = 1,
            distance_stop_animating = 0.0000001,
            legacy_computing_symbols_support = true,
        },
    },
    {
        "eandrju/cellular-automaton.nvim",
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        opts = {
            flavour = "frappe",
            transparent_background = true,

            integrations = {
                telescope = true,
                neo_tree = true,
                snacks = true,
                gitsigns = true,
                blink_cmp = true,
                lualine = {
                    all = function(colors)
                        return {
                            normal = {
                                a = { bg = colors.flamingo, fg = colors.base, gui = "bold" },
                                b = { bg = colors.surface0, fg = colors.flamingo },
                                c = { bg = "NONE", fg = colors.pink },
                            },
                            insert = {
                                a = { bg = colors.rosewater, fg = colors.base, gui = "bold" },
                                b = { bg = colors.surface0, fg = colors.rosewater },
                                c = { bg = "NONE", fg = colors.flamingo },
                            },
                            visual = {
                                a = { bg = colors.pink, fg = colors.base, gui = "bold" },
                                b = { bg = colors.surface0, fg = colors.pink },
                                c = { bg = "NONE", fg = colors.flamingo },
                            },
                            replace = {
                                a = { bg = colors.red, fg = colors.base, gui = "bold" },
                                b = { bg = colors.surface0, fg = colors.red },
                            },
                            command = {
                                a = { bg = colors.peach, fg = colors.base, gui = "bold" },
                                b = { bg = colors.surface0, fg = colors.peach },
                            },
                            terminal = {
                                a = { bg = colors.pink, fg = colors.base, gui = "bold" },
                                b = { bg = colors.surface0, fg = colors.pink },
                            },
                            inactive = {
                                a = { bg = "NONE", fg = colors.flamingo },
                                b = { bg = "NONE", fg = colors.surface1, gui = "bold" },
                                c = { bg = "NONE", fg = colors.overlay0 },
                            },
                        }
                    end,
                },
            },

            custom_highlights = function(colors)
                return {
                    NormalFloat = { bg = "NONE" },
                    FloatBorder = { bg = "NONE" },
                    CursorLine = { bg = "NONE" },

                    Pmenu = { bg = "NONE" },
                    PmenuSbar = { bg = "NONE" },

                    Visual = { bg = "#5a5060", fg = "#d4c5d5" },
                    VisualNOS = { bg = "#5a5060" },
                    Search = { bg = "#5a5060", fg = "#f4b8e4" },
                    CurSearch = { bg = "#f4b8e4", fg = "#5C3A21" },
                    IncSearch = { bg = "#eebebe", fg = "#5C3A21" },
                    Substitute = { bg = "#efad8a", fg = "#5C3A21" },

                    LineNr = { fg = "#9a8ea0" },
                    CursorLineNr = { fg = "#f4b8e4" },

                    Statement = { fg = "#eebebe" },
                    Type = { fg = "#c8a0e0" },
                    Identifier = { fg = "#c6d0f5" },
                    PreProc = { fg = "#eebebe" },
                    Special = { fg = "#f2d5cf" },
                    Constant = { fg = "#efad8a" },
                    String = { fg = "#e5c890" },
                    Comment = { fg = "#7a6e80" },
                    Function = { fg = "#f4b8e4" },
                    Conditional = { fg = "#eebebe" },
                    Repeat = { fg = "#eebebe" },
                    Label = { fg = "#e5c890" },
                    Operator = { fg = "#e89292" },
                    Keyword = { fg = "#f4b8e4" },
                    Exception = { fg = "#e89292" },
                    Include = { fg = "#e89292" },
                    Define = { fg = "#eebebe" },
                    Macro = { fg = "#efad8a" },
                    PreCondit = { fg = "#efad8a" },
                    StorageClass = { fg = "#d4a0e8" },
                    Structure = { fg = "#d4a0e8" },
                    Typedef = { fg = "#d4a0e8" },
                    Number = { fg = "#99d1db" },
                    Boolean = { fg = "#99d1db" },
                    Float = { fg = "#99d1db" },

                    ["@keyword"] = { fg = "#c8a0e0" },
                    ["@keyword.conditional"] = { fg = "#c8a0e0" },
                    ["@keyword.repeat"] = { fg = "#c8a0e0" },
                    ["@keyword.function"] = { fg = "#eebebe" },
                    ["@keyword.return"] = { fg = "#eebebe" },
                    ["@keyword.operator"] = { fg = "#e89292" },
                    ["@string"] = { fg = "#e5c890" },
                    ["@string.escape"] = { fg = "#f2d5cf" },
                    ["@string.regex"] = { fg = "#f2d5cf" },
                    ["@string.special"] = { fg = "#e5c890" },
                    ["@character"] = { fg = "#e5c890" },
                    ["@function"] = { fg = "#f4b8e4" },
                    ["@function.builtin"] = { fg = "#f4b8e4" },
                    ["@function.macro"] = { fg = "#f4b8e4" },
                    ["@function.call"] = { fg = "#f4b8e4" },
                    ["@variable"] = { fg = "#c6d0f5" },
                    ["@variable.builtin"] = { fg = "#efad8a" },
                    ["@constant"] = { fg = "#efad8a" },
                    ["@constant.builtin"] = { fg = "#efad8a" },
                    ["@constant.macro"] = { fg = "#efad8a" },
                    ["@type"] = { fg = "#ef9f76" },
                    ["@type.builtin"] = { fg = "#ef9f76" },
                    ["@type.qualifier"] = { fg = "#ef9f76" },
                    ["@type.definition"] = { fg = "#ef9f76" },
                    ["@number"] = { fg = "#99d1db" },
                    ["@boolean"] = { fg = "#99d1db" },
                    ["@float"] = { fg = "#99d1db" },
                    ["@operator"] = { fg = "#e89292" },
                    ["@comment"] = { fg = "#7a6e80" },
                    ["@punctuation"] = { fg = "#8a7e90" },
                    ["@punctuation.delimiter"] = { fg = "#8a7e90" },
                    ["@punctuation.bracket"] = { fg = "#8a7e90" },
                    ["@punctuation.special"] = { fg = "#f2d5cf" },
                    ["@parameter"] = { fg = "#c6d0f5" },
                    ["@parameter.reference"] = { fg = "#c6d0f5" },
                    ["@field"] = { fg = "#f2d5cf" },
                    ["@property"] = { fg = "#f2d5cf" },
                    ["@label"] = { fg = "#e5c890" },
                    ["@namespace"] = { fg = "#c6d0f5" },
                    ["@include"] = { fg = "#e89292" },
                    ["@conditional"] = { fg = "#eebebe" },
                    ["@repeat"] = { fg = "#eebebe" },
                    ["@exception"] = { fg = "#e89292" },
                    ["@tag"] = { fg = "#f4b8e4" },
                    ["@tag.delimiter"] = { fg = "#8a7e90" },
                    ["@tag.attribute"] = { fg = "#ca9ee6" },
                    ["@attribute"] = { fg = "#ef9f76" },
                    ["@error"] = { fg = "#e89292" },
                    ["@none"] = { fg = "#c6d0f5" },

                    ["@lsp.type.class"] = { fg = "#ef9f76" },
                    ["@lsp.type.struct"] = { fg = "#ef9f76" },
                    ["@lsp.type.enum"] = { fg = "#ef9f76" },
                    ["@lsp.type.interface"] = { fg = "#ef9f76" },
                    ["@lsp.type.type"] = { fg = "#ef9f76" },
                    ["@lsp.type.typeParameter"] = { fg = "#ef9f76" },
                    ["@lsp.type.parameter"] = { fg = "#c6d0f5" },
                    ["@lsp.type.variable"] = { fg = "#c6d0f5" },
                    SupermavenSuggestion = { fg = "#838ba7", italic = true },

                    BlinkCmpMenu = { bg = "NONE" },
                    BlinkCmpMenuBorder = { fg = "#d4c5d5", bg = "NONE" },
                    BlinkCmpMenuSelection = { bg = "NONE", fg = "#f4b8e4" },
                }
            end,
        },
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
