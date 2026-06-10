return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        fsautocomplete = { enabled = false },
        omnisharp = {
          handlers = {
            ["textDocument/inlayHint"] = function(err, result, ctx)
              if err then
                return
              end
              vim.lsp.inlay_hint.on_inlayhint(nil, result, ctx)
            end,
          },
          on_init = function(client, _)
            if client.name == "omnisharp" then
              client.server_capabilities.semanticTokensProvider = nil
            end
          end,
        },
      },
    },
  },
}
