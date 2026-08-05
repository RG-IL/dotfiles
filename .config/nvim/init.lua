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
vim.env.PATH = "/opt/homebrew/bin:" .. vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
vim.opt.fixendofline = false
