return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts = opts or {}
      require("snacks.notifier")

      -- הגדרת ה-picker
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.files = opts.picker.sources.files or {
        cmd = "fd",
        args = {
          "--type", "f",
          "--hidden",
          "--exclude", "Library",
          "--exclude", ".git",
          "--exclude", ".cache",
          "--exclude", ".local",
          "--exclude", ".ssh",
          "--exclude", ".vscode",
          "--exclude", ".npm",
          "--exclude", ".rustup",
          "--exclude", ".dotnet",
          "--exclude", ".wine",
          "--exclude", ".zsh_sessions",
          "--exclude", ".zsh_history",
          "--exclude", ".bash_sessions",
          "--exclude", ".ServiceHub",
          "--exclude", ".codex",
          "--exclude", ".android",
          "--exclude", ".Trash",
          "--exclude", "ghostty-shaders",
          "--exclude", "x.app",
          "--exclude", "Movies",
          "--exclude", "Music",
          "--exclude", ".penelope",
          "--exclude", "Pictures",
          "--exclude", ".nuget",
          "--exclude", "pygame",
          "--exclude", "Frameworks",
          "--exclude", "python3.14",
          "--exclude", "Applications",
          "--exclude", ".ruff_cache",
          "--exclude", "Chrome Apps.localized",
        },
      }

      return opts
    end, -- סגירת הפונקציה
  }, -- סגירת הטבלה הפנימית
} -- סגירת ה-return
