return {
  "yeasin50/manim.nvim",
  config = function()
    local function get_class(bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)
      local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
      for i = cursor_line, 1, -1 do
        local name = lines[i]:match("^class%s+(%w+)")
        if name then return name end
      end
      return nil
    end

    local function has_manim_import(bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)
      for _, line in ipairs(lines) do
        if line:match("import manim") or line:match("from manim") then
          return true
        end
      end
      return false
    end

    local function render(quality)
      local bufnr = vim.api.nvim_get_current_buf()
      local class_name = get_class(bufnr)
      if not class_name then return end
      if not has_manim_import(bufnr) then return end

      local file = vim.api.nvim_buf_get_name(bufnr)
      local dest = vim.fn.expand("~/Desktop") .. "/" .. class_name .. ".mp4"

      local shell_cmd = ("MEDIA_DIR=$(mktemp -d) && " ..
        "manim -q%s --media_dir \"$MEDIA_DIR\" %s %s && " ..
        "MP4=$(find \"$MEDIA_DIR\" -name '*.mp4' -not -path '*/partial_movie_files/*' -print -quit) && " ..
        "cp \"$MP4\" %s && rm -rf \"$MEDIA_DIR\" && " ..
        "mpv --geometry=960x540+50+50 %s"):format(
        quality, vim.fn.shellescape(file), class_name,
        vim.fn.shellescape(dest), vim.fn.shellescape(dest)
      )

      local pane_list = vim.fn.system("tmux list-panes -a -F '#{pane_id}'")
      if not pane_list:find(vim.g.manim_pane_id or "invalid", 1, true) then
        vim.g.manim_pane_id = nil
      end

      if not vim.g.manim_pane_id then
        local pane_info = vim.fn.system("tmux display-message -p '#{pane_id}'"):gsub("%s+", "")
        vim.fn.system("tmux split-window -v -l 30% -e MANIM_PANE=1 -t " .. pane_info)
        vim.g.manim_pane_id = vim.fn.system("tmux display-message -p '#{pane_id}'"):gsub("%s+", "")
      end

      vim.fn.system({ "tmux", "send-keys", "-t", vim.g.manim_pane_id, shell_cmd, "Enter" })
    end

    vim.keymap.set("n", "<leader>ml", function() render("l") end, { desc = "Manim 480p" })
    vim.keymap.set("n", "<leader>mm", function() render("m") end, { desc = "Manim 720p" })
    vim.keymap.set("n", "<leader>mh", function() render("h") end, { desc = "Manim 1080p" })
    vim.keymap.set("n", "<leader>mp", function() render("p") end, { desc = "Manim 1440p" })
    vim.keymap.set("n", "<leader>mk", function() render("k") end, { desc = "Manim 4K" })
  end,
}
