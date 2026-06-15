# AGENTS.md

This is `~/.config` — a user's dotfiles configuration directory, **not a project repo** or a git repository. Every subdirectory is an independent tool config.

## Architecture

- **No build/test/lint scripts** — configs are plain text files applied by each tool at startup.
- **Universal theme**: Catppuccin Frappe (`#303446` base, `#c6d0f5` text, `#f4b8e4` accent). All themed tools match: tmux, neovim, ghostty, yazi, bat, delta, atuin, lazygit, eza, gitlogue.
- **Tool chain**: Ghostty terminal → tmux → neovim. Ctrl+h/j/k/l flows through all three via vim-tmux-navigator.

## Key tools & configs

| Tool | Config | Notes |
|------|--------|-------|
| neovim | `nvim/` | LazyVim-based. Custom plugins in `lua/plugins/`. Tab=4 spaces, blackhole registers by default (`d`/`c`/`x`/`dd` → `"_`). |
| tmux | `tmux/tmux.conf` | Prefix `Ctrl+A`. Floating pane: `prefix+p`. Sesh session picker: `prefix+s`. LazyGit popup: `prefix+g`. Bluetooth popup: `prefix+b` via btui. |
| ghostty | `ghostty/config` | Hidden titlebar, custom GLSL cursor shaders (cursor_warp, ripple_cursor, x), background opacity 0.67, blur 40. Cmd+key forwarded as `\x01`+key (tmux prefix) for window management. Blur scripts in `ghostty/scripts/`: `*-blur.sh` (single-shot), `*-blur-loop.sh` (hold-to-repeat via Karabiner), `stop-blur.sh` (kill switch). |
| atuin | `atuin/config.toml` | `search_mode = "daemon-fuzzy"`, AI enabled, compact style, daemon autostart. Theme: catppuccin-frappe-sapphire. |
| yazi | `yazi/` | Plugins: full-border, what-size, smart-enter. Edit with nvim, open with macOS `open`. Sorted by size descending. |
| karabiner | `karabiner/karabiner.json` | Right Command+h/j/k/l → arrow keys. Cmd+Shift+J/K → Ghostty blur (tap=single, hold=loop after 0.5s). Opt+Shift+J/K → Ghostty opacity (tap=single, hold=loop after 0.5s). Both stop via `stop-blur.sh`. |
| gh | `gh/config.yml` | `git_protocol: https`, alias `co` = `pr checkout`. |
| delta | `delta/catppuccin.gitconfig` | Delta themes for all 4 Catppuccin flavors (latte, frappe, macchiato, mocha). Referenced by `.gitconfig`. |
| sesh | `sesh/sesh.toml` | `sesh` session manager. Two named sessions: `configs` (`~/.config`) and `coddy` (`~/coding/csharp/project/`). |
| bat | `bat/config` | Theme: `Pink-Rose`. |
| eza | `eza/theme.yml` | Full Catppuccin Frappe theme with per-filetype colors. |
| lazygit | `lazygit/config.yml` | Catppuccin Frappe color scheme. |
| gh-dash | `gh-dash/config.yml` | GitHub dashboard extension. |

## Neovim keymaps (`nvim/lua/config/keymaps.lua`)

Chords use `<M-C-S-X>` = Opt+Cmd+Shift+letter (macOS with `macos-option-as-alt`).

- `<M-C-S-W>` — save all buffers (`:wa`)
- `<M-C-S-Z>` — save all and quit (`:wqa`)
- `<M-C-S-T>` — toggle terminal (Snacks)
- `<M-C-S-R>` — run current file (Python: `./.venv/bin/python` or system, C#: `dotnet run`)
- `<M-C-S-S>` — grep in open buffers
- `<M-C-S-F>` — search word under cursor
- `<M-C-S-C>` — replace word under cursor in file
- `<M-C-S-L>` — luasnip expand/jump forward
- `<M-C-S-H>` — luasnip jump back
- `<leader>ci` — toggle `#pragma` (C#) / `# type: ignore` (Python) on selection/line
- `<leader>ce` — remove all comments (C# `//` / Python `#`)
- `<M-Tab>` — cycle buffers (circular)
- `<leader><leader>` — find files from `~` (Telescope)
- `<leader>ac` — Copilot on, SuperMaven off
- `<leader>as` — SuperMaven on, Copilot off
- `<leader>an` — both off
- DAP: `<leader>db` breakpoint, `<leader>dc` continue, `<leader>do` step over, `<leader>di` step into

## OpenCode config (`opencode/`)

- Model: `opencode/big-pickle`, `lsp: true`
- nvim plugin (`lua/plugins/opencode.lua`) with `<a-a>` for ask, `<C-x>` for select, `<C-.>` for toggle, `go` operator.
- Theme: `catppuccin-transparent` (in `tui.json`)

## Sensitive

- **`raycast/config.json`** contains API tokens — do not read or expose.
- **`atuin/permissions.ai.toml`** lists files the Atuin AI has write access to — review before modifying.
