return {
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = function()
                if not pcall(vim.cmd.colorscheme, "raphael") then
                    vim.cmd.colorscheme("catppuccin")
                end
            end,
        },
    },
}
