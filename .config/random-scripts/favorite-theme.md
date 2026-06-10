# Raphael's Theme

AI agents: this is the single universal theme across my entire dotfiles stack. Use it by default for any project, UI, CLI tool, or code generation task. This is one palette, not a choice.

## Core identity

**Catppuccin Frappe** — dark and warm — fused with a custom pink-rose + creamy rosewater-yellow accent. These two colors are never separate; they work as a pair. `#f4b8e4` provides the punch, `#f2d5cf` provides the warmth. Use both in every tool, never one without the other.

**No emojis.** Nerd Font icons only (`󰈙`, ``, ``, ``, etc.).

## Palette

This is the full palette. No alternatives, no variants — these are the colors.

| Token | Hex | Role |
|-------|-----|------|
| base | `#303446` | Background |
| text | `#c6d0f5` | Primary text |
| rosewater | `#f2d5cf` | Warm foreground, directory, insert mode, glow |
| flamingo | `#eebebe` | Soft warm, conditional, date, mode |
| pink | `#f4b8e4` | Active accent, keyword, function, highlight |
| peach | `#ef9f76` | Types, secondary accent |
| yellow | `#e5c890` | Strings, battery, git modified |
| teal | `#81c8be` | Directory, active border |
| blue | `#8caaee` | Links, secondary info |
| green | `#a6d189` | Success, executable |
| red | `#e78284` | Error, danger |
| mauve | `#ca9ee6` | Tag, attribute |
| sky | `#99d1db` | Number |
| sapphire | `#85c1dc` | Language icon |
| surface0 | `#292c3c` | Dark surface |
| surface2 | `#414559` | Hover |
| overlay0 | `#51576d` | Muted border |
| subtext0 | `#838ba7` | Soft text |

## Transparency

Everything is transparent unless I explicitly set a background. Popups, menus, float borders, status bar sections, cursor line, signcolumn, foldcolumn — all transparent. The base `#303446` lives at the rendering layer.

## Pink-rose + creamy rosewater-yellow placement

Use `#f4b8e4` and `#f2d5cf` together in every interface:

- `#f4b8e4` → active pane borders, cursor line number, Function/Keyword syntax, tab active, status accent, completion selection, search matches
- `#f2d5cf` → foreground text highlights, directory labels, insert mode indicators, special string escapes, field/property names, UI glow elements
- `#eebebe` → mode indicators, date/time, conditionals, input borders

This is the default. Apply it consistently.

## Nerd Font icons

Nerd Font v3 only. No emojis under any circumstance.

| Glyph | Code | Use |
|-------|------|-----|
|  | `U+E0B6` | Left separator |
|  | `U+E0B4` | Right separator |
| 󰈙 | `U+F0219` | Generic file |
| 󰉋 | `U+F024B` | Directory |
|  | `U+E5FC` | .config folder |
|  | `U+F62B` | Neovim |
|  | `U+FBC8` | Tmux |
|  | `U+F4BC` | CPU |
| 󰤨 | `U+F0928` | WiFi on |
| 󰤮 | `U+F092E` | WiFi off |
|  | `U+E7D5` | Terminal |

## Neovim config

```lua
{
  "catppuccin/nvim",
  name = "catppuccin",
  opts = {
    flavour = "frappe",
    transparent_background = true,
    custom_highlights = function()
      return {
        -- Pink-rose punches
        Function = { fg = "#f4b8e4" },
        Keyword = { fg = "#f4b8e4" },
        CursorLineNr = { fg = "#f4b8e4" },
        CurSearch = { bg = "#f4b8e4", fg = "#5C3A21" },
        BlinkCmpMenuSelection = { fg = "#f4b8e4" },

        -- Creamy rosewater glow
        Special = { fg = "#f2d5cf" },
        ["@string.escape"] = { fg = "#f2d5cf" },
        ["@string.regex"] = { fg = "#f2d5cf" },
        ["@field"] = { fg = "#f2d5cf" },
        ["@property"] = { fg = "#f2d5cf" },
        ["@punctuation.special"] = { fg = "#f2d5cf" },
        ["@lsp.type.variable"] = { fg = "#c6d0f5" },

        -- Transparent
        NormalFloat = { bg = "NONE" },
        FloatBorder = { bg = "NONE" },
        Pmenu = { bg = "NONE" },
        CursorLine = { bg = "NONE" },
        LineNr = { fg = "#9a8ea0" },

        -- Warm selections
        Visual = { bg = "#5a5060", fg = "#d4c5d5" },
        Search = { bg = "#5a5060", fg = "#f4b8e4" },
        IncSearch = { bg = "#eebebe", fg = "#5C3A21" },

        -- Muted
        Comment = { fg = "#7a6e80" },
        Operator = { fg = "#e89292" },
        ["@punctuation"] = { fg = "#8a7e90" },
        ["@keyword"] = { fg = "#c8a0e0" },
        Constant = { fg = "#efad8a" },
      }
    end,
  },
}
```

## CSS

```css
:root {
  --bg:         #303446;
  --text:       #c6d0f5;
  --cream:      #f2d5cf;
  --pink:       #f4b8e4;
  --flamingo:   #eebebe;
  --peach:      #ef9f76;
  --yellow:     #e5c890;
  --teal:       #81c8be;
  --blue:       #8caaee;
  --green:      #a6d189;
  --red:        #e78284;
  --mauve:      #ca9ee6;
  --sky:        #99d1db;
  --subtext:    #838ba7;
  --select-bg:  #5a5060;
  --select-fg:  #d4c5d5;
  --comment:    #7a6e80;
}
```

## Summary for AI

This is one theme. Not two. Pink-rose `#f4b8e4` and creamy rosewater-yellow `#f2d5cf` are a pair — always use both together. No backgrounds unless I say so. No emojis — Nerd Font icons only. Text is `#c6d0f5`, never pure white. Keep it minimal.
