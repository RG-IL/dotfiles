-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
vim.keymap.set({ "n", "v" }, "d", '"_d', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "c", '"_c', { noremap = true, silent = true })
vim.keymap.set({ "n", "v" }, "x", '"_x', { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fm", "<cmd>CellularAutomaton make_it_rain<CR>")
vim.keymap.set("n", "dd", '"_dd', { noremap = true, silent = true })
vim.keymap.set("n", "<M-Tab>", function()
    local bufs = vim.fn.getbufinfo({ buflisted = 1 })
    local cur = vim.fn.bufnr()

    for i, b in ipairs(bufs) do
        if b.bufnr == cur then
            local next_buf = bufs[i + 1] and bufs[i + 1].bufnr or bufs[1].bufnr
            vim.cmd("buffer " .. next_buf)
            return
        end
    end
end, { desc = "Next Buffer (circular)" })

-- Disable default Tab mapping to avoid breaking other completion plugins
vim.g.copilot_no_tab_map = true

-- Map Accept to Ctrl-y
vim.api.nvim_set_keymap("i", "<M-C-S-A>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
vim.keymap.set("n", "<M-C-S-E>", function()
    if vim.bo.modified then
        print("Save before exiting!")
    else
        vim.cmd("bd")
    end
end, { silent = true })
vim.keymap.set({ "n", "i" }, "<M-C-S-W>", "<cmd>wa<cr>", { silent = true })
vim.keymap.set({ "n", "i" }, "<M-C-S-Z>", "<cmd>wqa<cr>", { silent = true })
vim.keymap.set({ "n", "t" }, "<M-C-S-T>", function()
    require("snacks").terminal()
end, { silent = true, desc = "Toggle Terminal" })

local function get_python()
    local venv = "./.venv/bin/python"
    if vim.fn.executable(venv) == 1 then
        return venv
    end
    return vim.fn.exepath("python3") or "python3"
end

vim.keymap.set("n", "<M-C-S-R>", function()
    vim.cmd("w")
    vim.cmd("split")

    if vim.bo.filetype == "python" then
        local py = get_python()
        vim.cmd("terminal " .. py .. " " .. vim.fn.expand("%"))
        vim.cmd("startinsert")
    elseif vim.bo.filetype == "cs" then
        vim.cmd("terminal dotnet run")
        vim.cmd("startinsert")
    elseif vim.bo.filetype == "c" then
        local out = "." .. vim.fn.expand("%:r")
        vim.cmd("terminal gcc " .. vim.fn.expand("%") .. " -o " .. out .. " && ./" .. out)
        vim.cmd("startinsert")
    else
        print("Not a supported file type")
    end
end, { silent = true })

vim.keymap.set("n", "<M-C-S-S>", function()
    local ok, telescope = pcall(require, "telescope.builtin")
    if ok then
        telescope.live_grep({
            grep_open_files = true,
            prompt_title = "Grep in Open Buffers",
        })
    else
        require("snacks").picker.grep({
            buffers = true,
            title = "Grep in Open Buffers",
        })
    end
end, { silent = true, desc = "Grep in open buffers" })

vim.keymap.set("n", "<M-C-S-F>", function()
    local word = vim.fn.expand("<cword>")

    local ok, telescope = pcall(require, "telescope.builtin")
    if ok then
        telescope.grep_string({
            search = word,
            prompt_title = "Search word: " .. word,
        })
    else
        require("snacks").picker.grep({
            search = word,
            title = "Search word: " .. word,
        })
    end
end, { silent = true, desc = "Search word under cursor" })

vim.keymap.set("n", "<M-C-S-C>", function()
    local old_word = vim.fn.expand("<cword>")
    local new_word = vim.fn.input("Replace '" .. old_word .. "' with: ")

    if new_word == "" then
        return
    end

    local escaped_old = vim.fn.escape(old_word, [[/\]])

    vim.cmd("%s/\\V" .. escaped_old .. "/" .. new_word .. "/gc")
end, { silent = true, desc = "Replace word under cursor in whole file" })

local Snacks = require("snacks")

Snacks.toggle({
    name = "GitHub Copilot",
    color = { enabled = "azure", disabled = "orange" },
    get = function()
        return vim.g.copilot_enabled ~= false
    end,
    set = function(state)
        vim.g.copilot_enabled = state

        if state then
            pcall(vim.cmd, "Copilot enable")
        else
            pcall(vim.cmd, "Copilot disable")
            pcall(function()
                require("blink.cmp").cancel()
            end)
        end
    end,
})

local ls = require("luasnip")

-- Jump forward
vim.keymap.set({ "n", "i", "s" }, "<M-C-S-L>", function()
    if ls.expand_or_jumpable() then
        ls.expand_or_jump()
    end
end, { silent = true })

vim.keymap.set({ "n", "i", "s" }, "<M-C-S-H>", function()
    if ls.jumpable(-1) then
        ls.jump(-1)
    end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<M-C-S-J>", function()
    if ls.choice_active() then
        ls.change_choice(1)
    end
end, { silent = true })

vim.keymap.set({ "i", "s" }, "<M-C-S-K>", function()
    if ls.choice_active() then
        ls.change_choice(-1)
    end
end, { silent = true })

vim.keymap.set("n", "<leader><leader>", function()
    require("telescope.builtin").find_files({
        hidden = true,
        cwd = vim.fn.expand("~"),
    })
end, { desc = "Find files from home" })

-- --- Smart Toggle Ignore ---
local function smart_toggle_ignore()
    local ft = vim.bo.filetype
    local mode = vim.api.nvim_get_mode().mode
    local start_line, end_line

    if mode:match("[vV]") then
        vim.cmd("normal! \27")
        start_line = vim.fn.line("'<")
        end_line = vim.fn.line("'>")
    else
        start_line = vim.fn.line(".")
        end_line = start_line
    end

    if ft == "cs" then
        local line_above = vim.api.nvim_buf_get_lines(0, start_line - 2, start_line - 1, false)[1] or ""
        local line_below = vim.api.nvim_buf_get_lines(0, end_line, end_line + 1, false)[1] or ""

        if line_above:match("#pragma warning disable") and line_below:match("#pragma warning restore") then
            vim.api.nvim_buf_set_lines(0, end_line, end_line + 1, false, {})
            vim.api.nvim_buf_set_lines(0, start_line - 2, start_line - 1, false, {})
        else
            vim.api.nvim_buf_set_lines(0, end_line, end_line, false, { "#pragma warning restore" })
            vim.api.nvim_buf_set_lines(0, start_line - 1, start_line - 1, false, { "#pragma warning disable" })
        end
    elseif ft == "python" then
        local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
        local new_lines = {}
        for _, line in ipairs(lines) do
            if line:match("# type: ignore") then
                table.insert(new_lines, (line:gsub("%s*# type: ignore", "")))
            else
                table.insert(new_lines, line .. "  # type: ignore")
            end
        end
        vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, new_lines)
    end
end

-- --- Remove All Comments ---
local function remove_all_comments()
    local ft = vim.bo.filetype
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local new_lines = {}

    for _, line in ipairs(lines) do
        local cleaned_line = line
        if ft == "python" then
            cleaned_line = line:gsub("%s*#.*$", "")
        elseif ft == "cs" then
            cleaned_line = line:gsub("%s*//.*$", "")
        end

        if cleaned_line:match("%S") or line == "" then
            table.insert(new_lines, cleaned_line)
        end
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
end

-- --- Keymaps ---
vim.keymap.set({ "n", "v" }, "<leader>ci", smart_toggle_ignore, { desc = "Toggle Ignore (C#/Python)" })
vim.keymap.set("n", "<leader>ce", remove_all_comments, { desc = "Remove all comments" })
vim.keymap.set("n", "<leader>ac", function()
    vim.g.copilot_enabled = true
    vim.g.supermaven_enabled = false
    pcall(vim.cmd, "Copilot enable")
    pcall(vim.cmd, "SupermavenStop")
end, { desc = "Copilot on, SuperMaven off" })
vim.keymap.set("n", "<leader>as", function()
    vim.g.supermaven_enabled = true
    vim.g.copilot_enabled = false
    pcall(vim.cmd, "SupermavenStart")
    pcall(vim.cmd, "Copilot disable")
end, { desc = "SuperMaven on, Copilot off" })
vim.keymap.set("n", "<leader>an", function()
    vim.g.supermaven_enabled = false
    vim.g.copilot_enabled = false
    pcall(vim.cmd, "SupermavenStop")
    pcall(vim.cmd, "Copilot disable")
end, { desc = "Both off" })

-- which-key icons
local wk = require("which-key")
wk.add({
    { "<leader>ac", icon = "", desc = "Copilot on, SuperMaven off" },
    { "<leader>as", icon = "", desc = "SuperMaven on, Copilot off" },
    { "<leader>an", icon = "", desc = "Both off" },
})
