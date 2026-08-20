return {
    {
        "nvimdev/dashboard-nvim",
        opts = function(_, opts)
            local logo = [[
██████╗  ██████╗       ██╗ ██╗
██╔══██╗██╔════╝       ██║ ██║
██████╔╝██║  ███╗█████╗██║ ██║
██╔══██╗██║   ██║╚════╝██║ ██║
   ██║  ██║╚██████╔╝      ██║ ██████╗
   ╚═╝  ╚═╝ ╚═════╝       ╚═╝ ╚═════╝
      ]]

            opts = opts or {}
            opts.config = opts.config or {}
            opts.config.header = vim.split(string.rep("\n", 8) .. logo .. "\n\n", "\n")

            return opts
        end,
    },
}
