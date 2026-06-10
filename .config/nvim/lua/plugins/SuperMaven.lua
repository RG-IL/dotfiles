local ai_default_file = vim.fn.stdpath("config") .. "/.ai_default"

local function read_ai_default()
    local f = io.open(ai_default_file, "r")
    if f then
        local choice = f:read("*l")
        f:close()
        return choice
    end
    return nil
end

local function apply_ai_choice(choice)
    if choice == "s" then
        vim.g.supermaven_enabled = true
        vim.g.copilot_enabled = false
    elseif choice == "c" then
        vim.g.supermaven_enabled = false
        vim.g.copilot_enabled = true
    else
        vim.g.supermaven_enabled = false
        vim.g.copilot_enabled = false
    end
    if vim.g.copilot_enabled then
        pcall(vim.cmd, "Copilot enable")
    else
        pcall(vim.cmd, "Copilot disable")
    end
    if vim.g.supermaven_enabled then
        pcall(vim.cmd, "SupermavenStart")
    else
        pcall(vim.cmd, "SupermavenStop")
    end
end

vim.api.nvim_create_user_command("AIDEFAULT", function(input)
    local choice = input.args
    if choice ~= "n" and choice ~= "s" and choice ~= "c" then
        vim.notify("Usage: AIDEFAULT n|s|c (none/supermaven/copilot)", vim.log.levels.ERROR)
        return
    end
    local f = io.open(ai_default_file, "w")
    if f then
        f:write(choice)
        f:close()
    end
    apply_ai_choice(choice)
end, {
    nargs = 1,
    complete = function()
        return { "n", "s", "c" }
    end,
})

local default_choice = read_ai_default()
if default_choice then
    if default_choice == "s" then
        vim.g.supermaven_enabled = true
        vim.g.copilot_enabled = false
    elseif default_choice == "c" then
        vim.g.supermaven_enabled = false
        vim.g.copilot_enabled = true
    else
        vim.g.supermaven_enabled = false
        vim.g.copilot_enabled = false
    end
    vim.schedule(function()
        if vim.g.copilot_enabled then
            pcall(vim.cmd, "Copilot enable")
        else
            pcall(vim.cmd, "Copilot disable")
        end
    end)
end

return {
    "supermaven-inc/supermaven-nvim",
    config = function(_, opts)
        require("supermaven-nvim").setup(opts)
        if not vim.g.supermaven_enabled then
            pcall(function()
                require("supermaven-nvim.api").stop()
            end)
        end
    end,
    opts = {
        keymaps = {
            accept_suggestion_with_tab = false, -- none

            clear_suggestion = "<C-]>",
            accept_word = "<C-j>",
        },
        disable_inline_completion = false,
        ignore_filetypes = { cpp = true, bigfile = true, snacks_input = true, snacks_notif = true },
        log_level = "info",
        disable_keymaps = false,
        condition = function()
            return not vim.g.supermaven_enabled
        end,
    },
}
