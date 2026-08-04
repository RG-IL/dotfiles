# Design: Sketchybar packages widget — hover dropdown + click-to-upgrade

**Date:** 2026-08-04
**Status:** Approved

## Goal

Give the sketchybar packages widget (`widgets.packages`) a hover dropdown that
lists which brew formulas are outdated, color-code the count from green to
yellow to orange to red based on how many are outdated, and make a left-click
run `brew upgrade` to update them.

## Current behavior

- `widgets.packages` shows the outdated-formula count (`󰏗 N`) with the icon
  color-coded by `package_monitor.sh`, which reads `/tmp/status/packages`.
- The count is computed by the launchd status daemon (`status_daemon.sh` →
  `packages_info.sh`) so brew never runs under sketchybar (avoids macOS
  tccd/permission re-validation). The widget re-runs its script every 600s and
  on the `brew_upgrade` event (fired by a zsh `brew()` wrapper after
  `brew upgrade`).
- The active sketchybar theme (`gojo`) defines `YELLOW = ORANGE = RED`
  (`0xffe3c790`), so today's count scale is not visually distinct.
- The wifi widget already shows a hover popup (`mouse.entered` /
  `mouse.exited.global`), and the bluetooth widget already builds a dynamic
  multi-row popup with `sbar.remove()` + `position = "popup.<item>"` rows.
  Both are the templates for this feature.

## Approach

Extend the existing launchd-daemon pipeline. brew remains under launchd; the
widget only reads state files and writes a request flag.

### 1. Data flow

```
hover  → packages.lua reads /tmp/status/packages_list → builds popup rows (display-only)
click  → packages.lua writes /tmp/status/upgrade_requested → widget shows pulsing state
daemon → sees upgrade_requested (and no upgrade_running) → renames it to
         upgrade_running and spawns `nohup … upgrade_packages.sh &` → continues 1s loop
upgrade_packages.sh → `brew upgrade --formula` → re-runs packages_info.sh to refresh
         count + list files → removes upgrade_running → `sketchybar -m --trigger brew_upgrade`
widget → brew_upgrade event → package_monitor.sh re-runs → clears state, shows new count
```

### 2. Files

**`.config/tmux/scripts/packages_info.sh`** (modified)
- Emit the count on line 1, then one line per outdated formula:
  `name|installed|latest` (from `brew outdated --formula --verbose`).
- Keep the SIGCHLD reset and the try/except guarantee of a numeric exit 0.

**`.config/tmux/scripts/status_daemon.sh`** (modified)
- Split `packages_info.sh` output: `head -1` → `/tmp/status/packages`,
  remainder → `/tmp/status/packages_list`.
- Each cycle: if `upgrade_requested` exists and `upgrade_running` does not,
  rename it to `upgrade_running` and spawn `upgrade_packages.sh` in the
  background (detached). If `upgrade_running` exists, do nothing further.

**`.config/tmux/scripts/upgrade_packages.sh`** (new)
- Reset SIGCHLD (same portable-Ruby fix as packages_info.sh), then run
  `brew upgrade --formula`, redirecting output to a log file.
- Re-run `packages_info.sh` to refresh both state files.
- Remove `/tmp/status/upgrade_running`.
- Trigger `sketchybar -m --trigger brew_upgrade`.

**`.config/sketchybar/items/widgets/packages.lua`** (modified)
- Add a popup config (align = "center", background/radius/border mirroring the
  wifi widget).
- `mouse.entered`: read `/tmp/status/packages_list`; if empty (0 outdated), do
  not show the popup; otherwise build one display-only row per formula
  (`name  installed → latest`), capped at 12 rows with a trailing
  `… N more` row, and show the popup.
- `mouse.exited.global`: hide the popup and remove the rows.
- `mouse.clicked`: if no `upgrade_running` flag exists, write
  `/tmp/status/upgrade_requested` and immediately set the pulsing state in
  Lua (do not wait up to 600s for the next routine poll). The
  `brew_upgrade` event on completion clears it.
- Keep the existing `update_freq = 600` and `brew_upgrade` subscription.

**`.config/sketchybar/items/package_monitor.sh`** (modified)
- If `/tmp/status/upgrade_running` exists, show a pulsing state
  (`icon.symbol_anim=pulse`) and a spinner/“…” label instead of the count.
- Otherwise keep the count/color behavior with the new thresholds.

**`.config/sketchybar/colors.sh`** (modified)
- Distinct Catppuccin Frappe semantic colors for the count scale.

### 3. Count color scale

| Count | Color | Hex |
|-------|-------|-----|
| 0 | green | `0xffa6d189` |
| 1-2 | yellow | `0xffe5c890` |
| 3-5 | orange | `0xffef9f76` |
| 6+ | red | `0xffe78284` |

Applied to the icon (and label text). Only `package_monitor.sh` sources
`colors.sh`, so no other widget is affected.

### 4. Edge cases

- Rapid clicks while an upgrade is running are ignored (`upgrade_running`
  flag; `mouse.clicked` checks it before writing the request).
- The running state is shown immediately on click (set in Lua), cleared by
  the `brew_upgrade` event when the daemon finishes.
- 0 outdated → no popup on hover; a click still requests an upgrade, which
  `brew upgrade --formula` resolves as a no-op (“Already up-to-date”).
- `brew upgrade --formula` matches the `--formula`-only count exactly (casks
  are not counted and not upgraded).
- On upgrade failure, `packages_info.sh` still refreshes the state files
  (prints 0 on failure, consistent with current behavior).
- Popup capped at 12 rows so a large count cannot overflow the screen.

## Out of scope

- Per-package clickable rows in the dropdown (display-only only).
- Cask upgrade / cask counts.
- Changing the wifi or bluetooth widgets.
- Moving brew out of the launchd daemon.

## Files

- `.config/tmux/scripts/packages_info.sh` — emit count + per-formula list.
- `.config/tmux/scripts/status_daemon.sh` — split output; spawn upgrade job.
- `.config/tmux/scripts/upgrade_packages.sh` — run `brew upgrade --formula`,
  refresh state, clear flag, trigger event.
- `.config/sketchybar/items/widgets/packages.lua` — popup, hover, click.
- `.config/sketchybar/items/package_monitor.sh` — running state + color scale.
- `.config/sketchybar/colors.sh` — semantic green/yellow/orange/red.
