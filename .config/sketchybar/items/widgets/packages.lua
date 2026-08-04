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

-- Popup rows are created ONCE at load and only label-updated on hover, exactly
-- like wifi.lua's static popup item: the popup is shown/hidden by toggling
-- popup.drawing, never by destroying and rebuilding items, so hovering can't
-- flicker. Unused rows are hidden with drawing=false.
local rows = {}
for i = 1, MAX_ROWS do
	rows[i] = sbar.add("item", POPUP_PREFIX .. "row" .. i, {
		position = "popup." .. PACKAGES,
		width = POPUP_WIDTH,
		align = "left",
		drawing = false,
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
			string = "",
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

local more = sbar.add("item", POPUP_PREFIX .. "more", {
	position = "popup." .. PACKAGES,
	width = POPUP_WIDTH,
	align = "left",
	drawing = false,
	background = {
		height = 20,
		color = colors.transparent,
		border_width = 0,
	},
	icon = { drawing = false },
	label = {
		string = "",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Regular"],
			size = 11,
		},
		color = colors.with_alpha(colors.white, 0.55),
		padding_right = 10,
	},
})

local function refresh_popup()
	sbar.exec("cat " .. LIST_FILE, function(out)
		local entries = {}
		for line in (out or ""):gmatch("[^\r\n]+") do
			local name, installed, latest = line:match("^([^|]+)|([^|]*)|([^|]*)$")
			if name then
				entries[#entries + 1] = { name = name, installed = installed, latest = latest }
			end
		end
		local shown = math.min(#entries, MAX_ROWS)
		for i = 1, MAX_ROWS do
			if i <= shown then
				local e = entries[i]
				rows[i]:set({
					drawing = true,
					label = { string = e.name .. "  " .. e.installed .. " → " .. e.latest },
				})
			else
				rows[i]:set({ drawing = false })
			end
		end
		more:set({
			drawing = #entries > MAX_ROWS,
			label = { string = "… " .. (#entries - MAX_ROWS) .. " more" },
		})
		packages:set({ popup = { drawing = #entries > 0 } })
	end)
end

packages:subscribe("mouse.entered", function()
	sbar.exec("test -f " .. RUNNING_FILE .. " && echo 1 || echo 0", function(run)
		if (run or ""):find("1") then
			packages:set({ popup = { drawing = false } })
			return
		end
		refresh_popup()
	end)
end)

packages:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	packages:set({ popup = { drawing = false } })
end)

packages:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "left" then
		sbar.exec("test -f " .. RUNNING_FILE .. " && echo 1 || echo 0", function(run)
			if (run or ""):find("1") then
				return
			end
			sbar.exec("touch " .. REQUEST_FILE)
			packages:set({
				icon = { color = colors.grey },
				label = { string = "…", color = colors.grey },
			})
		end)
	end
end)

-- The Lua subscribe() binding above emits `--set widgets.packages script= ...`,
-- which empties the item's `script` property and would kill the monitor cadence
-- (routine/brew_upgrade). Re-assert the monitor script after all subscriptions.
packages:set({ script = "$CONFIG_DIR/items/package_monitor.sh" })

-- Fire on `brew upgrade` run in the terminal: a ~/.zshrc brew() wrapper sends
-- the brew_upgrade event; the status daemon sends it after a widget-click
-- upgrade finishes. `--add event` is idempotent, so re-running on reload is safe.
-- The sleep defers past the config rebuild, which would otherwise clobber the
-- update_mask set by this message.
sbar.exec("sleep 2; sketchybar -m --add event brew_upgrade; sketchybar -m --subscribe widgets.packages brew_upgrade")
