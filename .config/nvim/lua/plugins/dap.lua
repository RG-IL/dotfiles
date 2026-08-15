return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "nvim-neotest/nvim-nio",
            "rcarriga/nvim-dap-ui",
            "mfussenegger/nvim-dap-python",
            "theHamsta/nvim-dap-virtual-text",
            "mason-org/mason.nvim",
        },
        config = function()
            local dap = require("dap")
            local dapui = require("dapui")
            local dap_python = require("dap-python")

            -- A frame is part of the Rust std/core/alloc runtime (e.g. core::ops::function,
            -- std::rt::lang_start) when stepping past `main` lands there instead of exiting.
            local function is_runtime_frame(frame)
                if not frame then
                    return false
                end
                local path = frame.source and frame.source.path or ""
                local name = frame.name or ""
                return path:match("/rustc/")
                    or path:match("rustlib/src/rust/library")
                    or path:match("%.rustup/toolchains/")
                    or name:match("^std::")
                    or name:match("^core::")
                    or name:match("^alloc::")
                    or name:match("lang_start")
                    or name:match("call_once")
            end

            -- Close the std runtime view (e.g. function.rs) that stepping past `main`
            -- opened, by closing the current window/buffer showing it. Never closes the
            -- last tabpage or the last window.
            local function close_runtime_view()
                local buf = vim.api.nvim_get_current_buf()
                local name = vim.api.nvim_buf_get_name(buf)
                local is_runtime = name ~= ""
                    and (
                        name:match("function%.rs")
                        or name:match("/rustc/")
                        or name:match("rustlib/src/rust/library")
                        or name:match("%.rustup/toolchains/")
                    )
                if not is_runtime then
                    return
                end
                if #vim.api.nvim_list_wins() > 1 then
                    pcall(vim.api.nvim_win_close, 0, true)
                end
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end

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

            -- Rust / codelldb adapter (installed via Mason)
            local mason_registry = require("mason-registry")
            local codelldb_pkg = mason_registry.get_package("codelldb")
            local extension_path = codelldb_pkg:get_install_path() .. "/extension/"
            local codelldb_path = extension_path .. "adapter/codelldb"
            local libname = vim.loop.os_uname().sysname == "Darwin" and "liblldb.dylib" or "liblldb.so"
            local liblldb_path = extension_path .. "lldb/lib/" .. libname

            dap.adapters.codelldb = {
                type = "server",
                port = "${port}",
                host = "127.0.0.1",
                executable = {
                    command = codelldb_path,
                    args = { "--liblldb", liblldb_path, "--port", "${port}" },
                },
            }

            dap.configurations.rust = {
                {
                    name = "Launch (debug build)",
                    type = "codelldb",
                    request = "launch",
                    sourceLanguages = { "rust" },
                    showDisassembly = "never",
                    console = "integratedTerminal",
                    initCommands = {
                        "settings set target.process.thread.step-avoid-regexp ^(std|core|alloc)::",
                    },
                    program = function()
                        -- Locate the cargo workspace root from the current file
                        local cargo_toml = vim.fs.find("Cargo.toml", {
                            upward = true,
                            path = vim.fn.expand("%:p:h"),
                        })[1]
                        local root = cargo_toml and vim.fs.dirname(cargo_toml) or vim.fn.getcwd()
                        -- Build (synchronously) so the debug binary exists, then return it
                        local build = vim.system({ "cargo", "build" }, { cwd = root, text = true }):wait()
                        if build.code ~= 0 then
                            vim.notify("cargo build failed:\n" .. (build.stderr or ""), vim.log.levels.ERROR)
                            return nil
                        end
                        local meta = vim.json.decode(
                            vim.system(
                                { "cargo", "metadata", "--no-deps", "--format-version", "1" },
                                { cwd = root, text = true }
                            )
                                :wait().stdout
                        )
                        return meta.target_directory .. "/debug/" .. meta.packages[1].name
                    end,
                    cwd = "${workspaceFolder}",
                    stopOnEntry = false,
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

            -- Auto open/close UI (stock)
            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end

            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end

            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            -- When stepping (over/out) past the end of `main`, the program has actually
            -- finished, but LLDB lands in the Rust std runtime frame
            -- (core::ops::function / std::rt::lang_start) instead of exiting. Detect a step
            -- stop whose frame is in the std/core/alloc runtime and terminate the session.
            local function is_step_reason(reason)
                return reason == "step" or reason == "step over" or reason == "step out" or reason == "step in"
            end

            dap.listeners.before.event_stopped["auto_exit_runtime"] = function(session, body)
                if not is_step_reason(body and body.reason) then
                    return
                end
                local thread_id = body and body.threadId
                if not thread_id then
                    return
                end
                session:request(
                    "stackTrace",
                    { threadId = thread_id, levels = 1, startFrame = 0 },
                    function(err, response)
                        if err or not response or not response.stackFrames or #response.stackFrames == 0 then
                            return
                        end
                        if is_runtime_frame(response.stackFrames[1]) then
                            -- Terminate, then delete the runtime buffer (function.rs) via :bd.
                            require("dap").terminate()
                            vim.defer_fn(function()
                                vim.cmd("bd")
                            end, 150)
                        end
                    end
                )
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
