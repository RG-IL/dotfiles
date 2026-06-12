vim.api.nvim_create_user_command("CopilotStatusFile", function()
  local ok, status = pcall(function() return require("copilot.status").data end)
  if not ok then
    print("copilot.status not available")
    return
  end
  local file = "/tmp/copilot_status.json"
  local lines = vim.fn.split(vim.inspect(status), "\n")
  vim.fn.writefile(lines, file)
  print("Copilot status written to " .. file)
end, { desc = "Write Copilot status to /tmp/copilot_status.json" })

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("CopilotStatusFix", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "copilot" then
      local ok, status = pcall(require, "copilot.status")
      if ok then
        status.register_status_notification_handler(function(data)
          if data.status == "Warning" and data.message:match("ERR_INVALID_CHAR") then
            data.status = "Normal"
            data.message = ""
          end
        end)
      end
    end
  end,
})

return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    keys = {
      { "<leader>aa", "<cmd>CopilotChatToggle<cr>", desc = "Toggle Copilot Chat" },
      { "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code", mode = { "n", "v" } },
      { "<leader>af", "<cmd>CopilotChatFix<cr>", desc = "Fix Code", mode = { "n", "v" } },
      { "<leader>ar", "<cmd>CopilotChatReview<cr>", desc = "Review Code", mode = { "n", "v" } },
      { "<leader>ag", "<cmd>CopilotChatGenerate<cr>", desc = "Generate Code" },
    },
    opts = {
      auto_apply_diff = true,
    },
    
  },
  {
    "mcookly/bidi.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
