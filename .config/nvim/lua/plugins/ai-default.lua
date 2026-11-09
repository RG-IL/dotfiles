-- AIDEFAULT command: persist which AI assistant to use by default.
-- Choices: n = none, c = copilot (supermaven was removed from the config)
local ai_default_file = vim.fn.stdpath("config") .. "/.ai_default"

local function set_copilot(enable)
    vim.g.copilot_enabled = enable
    if enable then
        pcall(vim.cmd, "Copilot enable")
    else
        pcall(vim.cmd, "Copilot disable")
    end
end

local function read_choice()
    local f = io.open(ai_default_file, "r")
    if not f then
        return nil
    end
    local choice = f:read("*l")
    f:close()
    return choice
end

vim.api.nvim_create_user_command("AIDEFAULT", function(input)
    local choice = input.args
    if choice ~= "n" and choice ~= "c" then
        vim.notify("Usage: AIDEFAULT n|c (none/copilot)", vim.log.levels.ERROR)
        return
    end
    local f = io.open(ai_default_file, "w")
    if f then
        f:write(choice)
        f:close()
    end
    set_copilot(choice == "c")
end, {
    nargs = 1,
    complete = function()
        return { "n", "c" }
    end,
})

-- apply the saved default on startup; copilot.lua may load lazily, so
-- re-apply once it actually loads
local choice = read_choice()
if choice == "n" then
    set_copilot(false)
    vim.api.nvim_create_autocmd("User", {
        pattern = "LazyLoad",
        callback = function(event)
            if event.data and event.data:find("copilot", 1, true) then
                set_copilot(false)
            end
        end,
    })
elseif choice == "c" then
    vim.g.copilot_enabled = true
end

return {}
