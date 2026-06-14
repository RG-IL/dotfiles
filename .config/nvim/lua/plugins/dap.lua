return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "rcarriga/nvim-dap-ui",
            "mfussenegger/nvim-dap-python",
            "theHamsta/nvim-dap-virtual-text",
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            local dap_python = require("dap-python")

            dap.adapters.python = {
                type = "executable",
                command = vim.fn.exepath("python3"),
                args = { "-Xfrozen_modules=off", "-m", "debugpy.adapter" },
            }

            -- UI
            dapui.setup({
                layouts = {
                    {
                        elements = {
                            "scopes",
                            "breakpoints",
                            "stacks",
                            "watches",
                        },
                        size = 40,
                        position = "left",
                    },
                    {
                        elements = {
                            "repl",
                            "console",
                        },
                        size = 10,
                        position = "bottom",
                    },
                },
            })

            require("nvim-dap-virtual-text").setup({
                commented = true,
            })

            -- Python setup
            dap_python.setup(vim.fn.exepath("python3"))

            -- Default configuration
            dap.configurations.python = {
                {
                    type = "python",
                    request = "launch",
                    name = "Launch file",
                    program = "${file}",
                    console = "integratedTerminal",
                    pythonPath = function()
                        return vim.fn.exepath("python3")
                    end,
                },
            }

            -- Icons
            vim.fn.sign_define("DapBreakpoint", {
                text = "",
                texthl = "DiagnosticSignError",
            })

            vim.fn.sign_define("DapBreakpointRejected", {
                text = "",
                texthl = "DiagnosticSignError",
            })

            vim.fn.sign_define("DapStopped", {
                text = "",
                texthl = "DiagnosticSignWarn",
                linehl = "Visual",
                numhl = "DiagnosticSignWarn",
            })

            -- Auto save files when debugging starts
            dap.listeners.after.event_initialized["auto_save"] = function()
                vim.cmd("silent! wa")
            end

            -- Auto open/close UI
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end

            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end

            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            local opts = { noremap = true, silent = true }

            -- Keymaps
            vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, opts)
            vim.keymap.set("n", "<leader>dB", function()
                dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
            end, opts)

            vim.keymap.set("n", "<leader>dc", dap.continue, opts)
            vim.keymap.set("n", "<leader>dr", dap.restart, opts)

            vim.keymap.set("n", "<leader>do", dap.step_over, opts)
            vim.keymap.set("n", "<leader>di", dap.step_into, opts)
            vim.keymap.set("n", "<leader>dO", dap.step_out, opts)

            vim.keymap.set("n", "<leader>dq", dap.terminate, opts)
            vim.keymap.set("n", "<leader>du", dapui.toggle, opts)

            vim.keymap.set("n", "<leader>dh", function()
                require("dap.ui.widgets").hover()
            end, opts)

            -- Terminal escape (only for real terminals, not dap input)
            vim.keymap.set("t", "<Esc>", function()
                if vim.bo.buftype == "terminal" then
                    return [[<C-\><C-n>]]
                end
                return "<Esc>"
            end, { expr = true, noremap = true, silent = true })
        end,
    },
}
