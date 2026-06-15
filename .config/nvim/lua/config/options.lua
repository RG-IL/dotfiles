-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.termguicolors = true
vim.opt.ttyfast = true
vim.opt.lazyredraw = false
vim.opt.updatetime = 300
vim.opt.backupcopy = "yes"
vim.g.lazygit_config = false
vim.opt.spell = true
vim.opt.spelllang = { "en_us" }

vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    io.write("\027[6 q")
    io.flush()
  end,
})
