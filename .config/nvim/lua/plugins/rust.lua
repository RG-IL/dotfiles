return {
    {
        "mrcjkb/rustaceanvim",
        version = "^5",
        lazy = false, -- must load on startup
        init = function()
            vim.g.rustaceanvim = {
                tools = {
                    hover_actions = { auto_focus = true },
                },
                server = {
                    default_settings = {
                        ["rust-analyzer"] = {
                            cargo = {
                                allFeatures = true,
                                buildScripts = { enable = true },
                            },
                            -- Native (on-change) diagnostics, so errors show live while editing.
                            diagnostics = {
                                experimental = { enable = true },
                            },
                            -- No flycheck on save: saving only formats via rustfmt. The live
                            -- `rust-analyzer` source already surfaces errors as you type.
                            checkOnSave = false,
                            procMacro = {
                                enable = true,
                            },
                        },
                    },
                },
                dap = {
                    -- dap.adapters.codelldb is pre-registered in dap.lua; we only disable
                    -- rustaceanvim's auto-added debuggables to avoid duplicate configs.
                    autoload_configurations = false,
                },
            }

            -- The `rustc` diagnostic source (rust-analyzer's separate rustc pass / save-time
            -- flycheck) duplicates errors already reported by the live `rust-analyzer` source.
            -- Drop it so only the live analyzer's diagnostics are shown.
            vim.api.nvim_create_autocmd("VimEnter", {
                once = true,
                callback = function()
                    local default = vim.lsp.handlers["textDocument/publishDiagnostics"]
                    vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, cfg)
                        if result and result.diagnostics then
                            result.diagnostics = vim.tbl_filter(function(d)
                                return d.source ~= "rustc"
                            end, result.diagnostics)
                        end
                        return default(err, result, ctx, cfg)
                    end
                end,
            })
        end,
    },
}
