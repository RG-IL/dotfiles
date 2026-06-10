-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove("o")
    end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
    pattern = "*",
    callback = function()
        -- Define all 4 core Neovim spelling groups
        local spell_groups = { "SpellBad", "SpellCap", "SpellLocal", "SpellRare" }

        for _, group in ipairs(spell_groups) do
            vim.api.nvim_set_hl(0, group, {
                fg = "#EF9090",
                undercurl = true,
                bold = true,
                italic = true,
                sp = "#EF9090", -- Set the color of the undercurl to match the foreground color
            })
        end
    end,
})
