require("config.lazy")
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.api.nvim_create_autocmd("FileType", {
    pattern = "cs",
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.expandtab = true
    end,
})
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.defer_fn(function()
            vim.cmd("syntax off")
            vim.cmd("syntax on")
            vim.cmd("colorscheme catppuccin")
        end, 30)
    end,
})
vim.env.PATH = "/opt/homebrew/bin:" .. vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
vim.opt.fixendofline = false
