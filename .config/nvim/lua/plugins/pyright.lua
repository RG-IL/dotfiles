return {
    {
        "github/copilot.vim",
    },
    {
        "neovim/nvim-lspconfig",
        ---@class PluginLspOpts
        opts = {
            ---@type lspconfig.options
            servers = {
                pyright = {
                    before_init = function(_, config)
                        config.settings = config.settings or {}
                        config.settings.python = config.settings.python or {}
                        config.settings.python.pythonPath =
                            "/Library/Frameworks/Python.framework/Versions/3.14/bin/python3"
                    end,
                    settings = {
                        python = {
                            analysis = {
                                diagnosticSeverityOverrides = {
                                    reportIncompatibleMethodOverride = "none",
                                },
                            },
                        },
                    },
                },
                ruff = {
                    on_attach = function(client)
                        client.server_capabilities.diagnosticProvider = false
                    end,
                },
            },
        },
        init = function()
            -- disable LSP hover popup
            vim.lsp.handlers["textDocument/hover"] = function() end

            -- disable signature help popup
            vim.lsp.handlers["textDocument/signatureHelp"] = function() end

            -- disable inlay hints globally
            pcall(function()
                vim.lsp.inlay_hint.enable(false)
            end)

            -- keep inlay hints disabled per buffer
            vim.api.nvim_create_autocmd("LspAttach", {
                callback = function(args)
                    if vim.lsp.inlay_hint then
                        pcall(vim.lsp.inlay_hint.enable, args.buf, false)
                    end
                end,
            })
        end,
    },

    {
        "saghen/blink.cmp",
        opts = {
            keymap = {
                ["<Tab>"] = { "select_next", "fallback" },
                ["<S-Tab>"] = { "select_prev", "fallback" },
                ["<C-e>"] = { "cancel", "fallback" },
                ["<CR>"] = { "accept", "fallback" },
            },
            completion = {
                menu = {
                    winblend = 0,
                },
                documentation = {
                    auto_show = false,
                },
            },
            sources = {
                -- ... מקורות אחרים ...
                providers = {
                    copilot = {
                        name = "copilot",
                        module = "blink-copilot",
                        -- הוסף את השורה הזו:
                        enabled = function()
                            return vim.g.copilot_enabled ~= false
                        end,

                        score_offset = 100,
                        async = true,
                    },
                },
            },
        },
    },
}
