# Sketchybar Packages Widget (Hover Dropdown + Click-to-Upgrade) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the sketchybar packages widget a hover dropdown listing outdated brew formulas, a green→yellow→orange→red count scale, and click-to-upgrade via the launchd status daemon.

**Architecture:** The launchd status daemon (`status_daemon.sh`) already computes brew state and writes `/tmp/status/packages`. We extend `packages_info.sh` to also emit a per-formula list, split it into a second state file, and add a flag-file IPC so a sketchybar click makes the daemon spawn `upgrade_packages.sh` (which runs `brew upgrade --formula` and then triggers the existing `brew_upgrade` event). The sketchybar Lua widget reads state files for the hover popup and writes the request flag on click. brew never runs under sketchybar.

**Tech Stack:** bash (launchd daemon), python3 (brew wrapper with SIGCHLD reset), Lua (sketchybar config), sketchybar CLI, Homebrew.

## Global Constraints

- brew runs ONLY under the launchd daemon chain (`status_daemon.sh`, `packages_info.sh`, `upgrade_packages.sh`). Never spawn brew from sketchybar.
- Formula-only: use `--formula` for both count and upgrade. Casks are not counted, listed, or upgraded.
- Every brew invocation must go through the python wrapper that calls `signal.signal(signal.SIGCHLD, signal.SIG_DFL)` first (inherited SIG_IGN crashes Homebrew's portable Ruby).
- Count color scale (exact hex, Catppuccin Frappe): 0 → `0xffa6d189` (green), 1-2 → `0xffe5c890` (yellow), 3-5 → `0xffef9f76` (orange), 6+ → `0xffe78284` (red).
- Files under `~/.config/tmux` and `~/.config/sketchybar` are symlinks into this repo — edit the repo paths in place; do NOT use a git worktree (live config must be the files under test).
- Daemon spawns `upgrade_packages.sh` detached with `nohup … &`; the running state is tracked by the file `/tmp/status/upgrade_running`.
- Commit message style: short imperative subject, e.g. `feat: ...`.
- Never delete `~/JumpGame` or `~/JumpGame_Github`.

---

### Task 1: Emit the outdated-formula list alongside the count

**Files:**
- Modify: `.config/tmux/scripts/packages_info.sh` (whole python body, keep header comment, add note about emitting the list)
- Modify: `.config/tmux/scripts/status_daemon.sh` (file-var block and the `cycle % 600` branch)

**Interfaces:**
- Produces: `packages_info.sh` now prints the count on line 1, then one `name|installed|latest` line per outdated formula. `/tmp/status/packages` holds only the count (line 1); `/tmp/status/packages_list` holds the remaining lines. Later tasks read both files.

- [ ] **Step 1: Rewrite the python body of `packages_info.sh`**

Replace everything from `import os, signal, subprocess` to the final `'` (lines 19-35) with:

```python
import os, signal, subprocess, re

signal.signal(signal.SIGCHLD, signal.SIG_DFL)
env = dict(os.environ)
try:
    r = subprocess.run(
        ["/opt/homebrew/bin/brew", "outdated", "--formula", "--verbose"],
        capture_output=True,
        text=True,
        env=env,
    )
except Exception:
    print(0)
    raise SystemExit(0)
if r.returncode != 0:
    print(0)
else:
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    print(len(lines))
    for l in lines:
        m = re.match(r"^([^ (]+) \(([^)]*)\) < (.+)$", l)
        if m:
            name, installed, latest = m.groups()
            print(f"{name}|{installed}|{latest}")
        else:
            print(f"{l}| | ")
```

Update the header comment: the script now emits the count on line 1 plus one `name|installed|latest` line per outdated formula.

- [ ] **Step 2: Verify `packages_info.sh` output**

Run: `~/.config/tmux/scripts/packages_info.sh`
Expected: line 1 is a number (the outdated count), and each following line matches `^[^|]+\|[^|]*\|[^|]*$`. With the current state it should end with lines like `sdl3|3.4.12|3.4.14`. Also run `echo "exit=$?"` — must print `exit=0`.

- [ ] **Step 3: Add the `packages_list` file variable in `status_daemon.sh`**

In the file-variable block (near line 31 `packages_file=...`), add:

```bash
packages_list_file="$STATUS_DIR/packages_list"
```

- [ ] **Step 4: Split the output in the `cycle % 600` branch**

Replace the current branch:

```bash
  if ((cycle % 600 == 0)); then
    "$SCRIPTS/packages_info.sh" > "$packages_file.tmp" 2>/dev/null && mv "$packages_file.tmp" "$packages_file"
  fi
```

with:

```bash
  if ((cycle % 600 == 0)); then
    if "$SCRIPTS/packages_info.sh" > "$packages_file.tmp" 2>/dev/null; then
      head -n 1 "$packages_file.tmp" > "$packages_file"
      tail -n +2 "$packages_file.tmp" > "$packages_list_file"
      rm -f "$packages_file.tmp"
    fi
  fi
```

- [ ] **Step 5: Verify the split produces both files**

Run:
```bash
~/.config/tmux/scripts/packages_info.sh > /tmp/status/packages.tmp
head -n 1 /tmp/status/packages.tmp > /tmp/status/packages
tail -n +2 /tmp/status/packages.tmp > /tmp/status/packages_list
rm -f /tmp/status/packages.tmp
cat /tmp/status/packages
wc -l /tmp/status/packages_list
```
Expected: `cat /tmp/status/packages` prints a bare number (e.g. `5`); `wc -l` prints the same number of lines (5) with each line `name|installed|latest`.

- [ ] **Step 6: Commit**

```bash
git add .config/tmux/scripts/packages_info.sh .config/tmux/scripts/status_daemon.sh
git commit -m "feat: emit outdated-formula list from packages_info.sh"
```

---

### Task 2: Add the `upgrade_packages.sh` upgrade runner

**Files:**
- Create: `.config/tmux/scripts/upgrade_packages.sh` (must be executable)

**Interfaces:**
- Consumes: `/tmp/status/upgrade_running` (present while an upgrade is in flight), `packages_info.sh` (Task 1 output format), the `brew_upgrade` sketchybar event (added by `packages.lua` at config load).
- Produces: `/tmp/status/packages_upgrade.log` (brew output), refreshed `/tmp/status/packages` + `/tmp/status/packages_list`, removal of `/tmp/status/upgrade_running`, and a `brew_upgrade` event trigger.

> **Warning:** Running this task's verification performs a REAL `brew upgrade --formula` (updates every currently-outdated formula). Confirm with the user before executing Step 4.

- [ ] **Step 1: Write `upgrade_packages.sh`**

```bash
#!/usr/bin/env bash
# Runs `brew upgrade --formula` under the launchd status daemon's responsibility
# chain, refreshes the package state files, and clears the running flag. Spawned
# detached by status_daemon.sh when the user clicks the sketchybar packages
# widget. brew runs under launchd, never under sketchybar.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
STATUS_DIR="/tmp/status"
LOG="$STATUS_DIR/packages_upgrade.log"
PACKAGES_FILE="$STATUS_DIR/packages"
LIST_FILE="$STATUS_DIR/packages_list"

/usr/bin/python3 -c '
import os, signal, subprocess
signal.signal(signal.SIGCHLD, signal.SIG_DFL)
env = dict(os.environ)
subprocess.run(
    ["/opt/homebrew/bin/brew", "upgrade", "--formula"],
    env=env,
)
' > "$LOG" 2>&1

# Refresh state files (same split as status_daemon.sh).
if "$SCRIPTS/packages_info.sh" > "$STATUS_DIR/packages.tmp" 2>/dev/null; then
  head -n 1 "$STATUS_DIR/packages.tmp" > "$PACKAGES_FILE"
  tail -n +2 "$STATUS_DIR/packages.tmp" > "$LIST_FILE"
  rm -f "$STATUS_DIR/packages.tmp"
fi

rm -f "$STATUS_DIR/upgrade_running"
sketchybar -m --trigger brew_upgrade 2>/dev/null
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x .config/tmux/scripts/upgrade_packages.sh`

- [ ] **Step 3: Syntax-check the script**

Run: `bash -n .config/tmux/scripts/upgrade_packages.sh && echo OK`
Expected: `OK`

- [ ] **Step 4: Run it end-to-end (REAL upgrade — confirm with user first)**

Run:
```bash
touch /tmp/status/upgrade_running
~/.config/tmux/scripts/upgrade_packages.sh
```
Expected: brew upgrades all outdated formulas (watch `~/.config/tmux/scripts/../tmux/scripts` progress in `/tmp/status/packages_upgrade.log`), `/tmp/status/upgrade_running` is removed, `/tmp/status/packages` now reads `0`, `/tmp/status/packages_list` is empty, and sketchybar's packages widget re-renders (label shows nothing/green).

- [ ] **Step 5: Commit**

```bash
git add .config/tmux/scripts/upgrade_packages.sh
git commit -m "feat: add brew upgrade runner for the packages widget"
```

---

### Task 3: Spawn the upgrade from the daemon on a request flag

**Files:**
- Modify: `.config/tmux/scripts/status_daemon.sh`

**Interfaces:**
- Consumes: `/tmp/status/upgrade_requested` (written by `packages.lua`), Task 2's `upgrade_packages.sh`.
- Produces: renames the request flag to `/tmp/status/upgrade_running` and spawns `upgrade_packages.sh` detached once.

- [ ] **Step 1: Add the flag file variables**

In the file-variable block (near `packages_list_file`), add:

```bash
upgrade_requested="$STATUS_DIR/upgrade_requested"
upgrade_running="$STATUS_DIR/upgrade_running"
```

- [ ] **Step 2: Add the spawn check in the loop**

Immediately after the `cycle % 600` packages branch (before the `if tmux has-session` block), add:

```bash
  if [[ -f "$upgrade_requested" && ! -f "$upgrade_running" ]]; then
    mv "$upgrade_requested" "$upgrade_running"
    nohup "$SCRIPTS/upgrade_packages.sh" >/dev/null 2>&1 &
  fi
```

- [ ] **Step 3: Syntax-check**

Run: `bash -n ~/.config/tmux/scripts/status_daemon.sh && echo OK`
Expected: `OK`

- [ ] **Step 4: Restart the daemon and verify the spawn path**

Run:
```bash
launchctl kickstart -k gui/$(id -u)/com.raphael.tmux-status
sleep 1
touch /tmp/status/upgrade_requested
sleep 2
ls -la /tmp/status/upgrade_requested /tmp/status/upgrade_running 2>&1
```
Expected: `upgrade_requested` is gone, `upgrade_running` exists, and a `upgrade_packages.sh` process is running (`pgrep -f upgrade_packages.sh`). Then clean up: if an upgrade started that you did not want, `pkill -f upgrade_packages.sh; rm -f /tmp/status/upgrade_running`. Otherwise let it finish.

- [ ] **Step 5: Commit**

```bash
git add .config/tmux/scripts/status_daemon.sh
git commit -m "feat: spawn brew upgrade from status daemon on request flag"
```

---

### Task 4: Running state + Catppuccin count scale in the monitor script

**Files:**
- Modify: `.config/sketchybar/colors.sh`
- Modify: `.config/sketchybar/items/package_monitor.sh`

**Interfaces:**
- Consumes: `/tmp/status/packages` (count), `/tmp/status/upgrade_running` (running flag).
- Produces: icon/label color by count tier, pulsing icon + `…` label while an upgrade runs.

- [ ] **Step 1: Update the four scale colors in `colors.sh`**

Replace the `RED`, `ORANGE`, `YELLOW`, `GREEN` lines (keep `WHITE`, `GREY`, `ACCENT` unchanged):

```sh
RED=0xffe78284
ORANGE=0xffef9f76
YELLOW=0xffe5c890
GREEN=0xffa6d189
```

- [ ] **Step 2: Rewrite `package_monitor.sh`**

```bash
#!/bin/bash
# Counts the raw brew-outdated tally written by the launchd status daemon
# (/tmp/status/packages, from packages_info.sh) and color-codes the item.
# While the daemon runs `brew upgrade` (flag file present) it shows a pulsing
# "…" instead of the count. The daemon runs brew under launchd, so sketchybar
# never spawns brew.
source "$CONFIG_DIR/colors.sh"

COUNT="$(cat /tmp/status/packages 2>/dev/null)"
COUNT="${COUNT:-0}"

COLOR=$GREEN
LABEL_PAD_R=8
ANIM=off

if [[ -f /tmp/status/upgrade_running ]]; then
    COLOR=$GREY
    COUNT="…"
    ANIM=pulse
else
    case "$COUNT" in
        [6-9]|[1-9][0-9])
            COLOR=$RED
            ;;
        [3-5])
            COLOR=$ORANGE
            ;;
        [1-2])
            COLOR=$YELLOW
            ;;
        0)
            COLOR=$GREEN
            COUNT=""
            LABEL_PAD_R=0
            ;;
    esac
fi

sketchybar --set $NAME label="$COUNT" icon.color="$COLOR" label.color="$COLOR" label.padding_right="$LABEL_PAD_R" icon.symbol_anim="$ANIM"
```

- [ ] **Step 3: Verify the color tiers**

Run (with a real sketchybar running):
```bash
CONFIG_DIR=~/.config/sketchybar NAME=widgets.packages ~/.config/sketchybar/items/package_monitor.sh
sketchybar -m --query widgets.packages | grep -E '"(value|color)"' | head -4
```
With 0 outdated: expected label value `""` and icon/label color `0xffa6d189`.

- [ ] **Step 4: Verify the running state**

Run:
```bash
touch /tmp/status/upgrade_running
CONFIG_DIR=~/.config/sketchybar NAME=widgets.packages ~/.config/sketchybar/items/package_monitor.sh
sketchybar -m --query widgets.packages | grep -E '"(value|color|symbol_anim)"' | head -6
rm -f /tmp/status/upgrade_running
```
Expected: label value `…` and `symbol_anim` `pulse`. After `rm`, run the script again and re-query: label value `""`, `symbol_anim` `off`.

- [ ] **Step 5: Commit**

```bash
git add .config/sketchybar/colors.sh .config/sketchybar/items/package_monitor.sh
git commit -m "feat: add running state and catppuccin count scale to packages widget"
```

---

### Task 5: Hover dropdown + click-to-upgrade in `packages.lua`

**Files:**
- Modify: `.config/sketchybar/items/widgets/packages.lua` (rewrite)

**Interfaces:**
- Consumes: `/tmp/status/packages_list` (`name|installed|latest` lines from Task 1), `/tmp/status/upgrade_running`, writes `/tmp/status/upgrade_requested`.
- Produces: hover popup rows (display-only, capped at 12 + "… N more"), left-click writes the request flag and shows an immediate pulsing state.

- [ ] **Step 1: Rewrite `packages.lua`**

```lua
local colors = require("colors")
local settings = require("settings")

local PACKAGES = "widgets.packages"
local POPUP_PREFIX = "widgets.packages.popup."
local POPUP_WIDTH = 260
local MAX_ROWS = 12

local LIST_FILE = "/tmp/status/packages_list"
local RUNNING_FILE = "/tmp/status/upgrade_running"
local REQUEST_FILE = "/tmp/status/upgrade_requested"

local packages = sbar.add("item", PACKAGES, {
	position = "right",
	scroll_texts = false,
	script = "$CONFIG_DIR/items/package_monitor.sh",
	icon = {
		string = "󰏗",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Regular"],
			size = 20.0,
		},
		padding_left = 8,
		padding_right = 4,
	},
	label = {
		string = "",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
		padding_right = 8,
	},
	popup = {
		align = "center",
		background = {
			color = colors.popup.bg,
			corner_radius = 12,
			border_width = 1,
			border_color = colors.popup.border,
		},
	},
	updates = true,
	update_freq = 600,
})

local function remove_popup_items()
	sbar.remove("/" .. POPUP_PREFIX:gsub("%.", "\\.") .. ".*/")
end

local function hide_popup()
	packages:set({ popup = { drawing = false } })
	remove_popup_items()
end

local function show_popup()
	sbar.exec("cat " .. LIST_FILE, function(out)
		local rows = {}
		for line in (out or ""):gmatch("[^\r\n]+") do
			local name, installed, latest = line:match("^([^|]+)|([^|]*)|([^|]*)$")
			if name then
				rows[#rows + 1] = { name = name, installed = installed, latest = latest }
			end
		end
		if #rows == 0 then
			packages:set({ popup = { drawing = false } })
			return
		end
		remove_popup_items()
		local shown = math.min(#rows, MAX_ROWS)
		for i = 1, shown do
			local row = rows[i]
			sbar.add("item", POPUP_PREFIX .. "row" .. i, {
				position = "popup." .. PACKAGES,
				width = POPUP_WIDTH,
				align = "left",
				background = {
					height = 20,
					color = colors.transparent,
					border_width = 0,
				},
				icon = {
					string = "󰏗",
					font = {
						family = settings.font.text,
						style = settings.font.style_map["Regular"],
						size = 13.0,
					},
					color = colors.with_alpha(colors.white, 0.55),
					padding_left = 10,
					padding_right = 6,
				},
				label = {
					string = row.name .. "  " .. row.installed .. " → " .. row.latest,
					font = {
						family = settings.font.text,
						style = settings.font.style_map["Bold"],
						size = 12,
					},
					color = colors.white,
					padding_right = 10,
				},
			})
		end
		if #rows > MAX_ROWS then
			sbar.add("item", POPUP_PREFIX .. "more", {
				position = "popup." .. PACKAGES,
				width = POPUP_WIDTH,
				align = "left",
				background = {
					height = 20,
					color = colors.transparent,
					border_width = 0,
				},
				icon = { drawing = false },
				label = {
					string = "… " .. (#rows - MAX_ROWS) .. " more",
					font = {
						family = settings.font.text,
						style = settings.font.style_map["Regular"],
						size = 11,
					},
					color = colors.with_alpha(colors.white, 0.55),
					padding_right = 10,
				},
			})
		end
		packages:set({ popup = { drawing = true } })
	end)
end

packages:subscribe("mouse.entered", function()
	sbar.exec("test -f " .. RUNNING_FILE .. " && echo 1 || echo 0", function(run)
		if (run or ""):find("1") then
			packages:set({ popup = { drawing = false } })
			return
		end
		show_popup()
	end)
end)

packages:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	hide_popup()
end)

packages:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec("test -f " .. RUNNING_FILE .. " && echo 1 || echo 0", function(run)
			if (run or ""):find("1") then
				return
			end
			sbar.exec("touch " .. REQUEST_FILE)
			packages:set({
				icon = { symbol_anim = "pulse" },
				label = { string = "…" },
			})
		end)
	end
end)

-- Fire on `brew upgrade` run in the terminal: a ~/.zshrc brew() wrapper sends
-- the brew_upgrade event; the status daemon sends it after a widget-click
-- upgrade finishes. `--add event` is idempotent, so re-running on reload is safe.
sbar.exec("sleep 2; sketchybar -m --add event brew_upgrade; sketchybar -m --subscribe widgets.packages brew_upgrade")
```

- [ ] **Step 2: Reload sketchybar**

Run: `sketchybar --reload`
Expected: no errors; the `widgets.packages` item still present (`sketchybar -m --query widgets.packages`), and the `󰏗` icon visible on the bar.

- [ ] **Step 3: Verify the hover dropdown**

With outdated formulas present (re-run `packages_info.sh` + split first if the list is empty), hover the packages icon.
Expected: a popup appears listing each formula as `name  installed → latest` (e.g. `lazygit  0.63.1 → 0.64.0`). Moving the mouse away hides it. With the count at 0, hovering shows nothing.

- [ ] **Step 4: Verify click-to-upgrade (performs a real upgrade — confirm with user first)**

Left-click the packages icon.
Expected: immediately shows a pulsing `…`; `/tmp/status/upgrade_requested` appears, the daemon renames it to `upgrade_running` and spawns the upgrade; when finished, `packages` reads `0`, `packages_list` is empty, the pulse clears, and the count shows nothing/green.

- [ ] **Step 5: Commit**

```bash
git add .config/sketchybar/items/widgets/packages.lua
git commit -m "feat: hover dropdown and click-to-upgrade for the packages widget"
```

---

## Self-Review Notes

- Every spec requirement maps to a task: list output (T1), state split (T1), upgrade runner (T2), daemon spawn (T3), running state + color scale (T4), popup + hover + click (T5). Edge cases (rapid-click guard, 0-outdated no-op, `--formula` matching, failure refresh, 12-row cap) are covered in Tasks 2-5.
- No worktree: live config files are symlinked into the repo (see Global Constraints).
- No placeholder content; every step has concrete code and a runnable verification with an expected result.
