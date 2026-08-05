local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local battery = sbar.add("item", "widgets.battery", {
	position = "right",
	padding_left = -1,
	icon = {
		font = {
			style = settings.font.style_map["Bold"],
			size = 17.0,
		},
		padding_left = 8,
		padding_right = 4,
	},
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
		color = colors.white,
		padding_right = 10,
	},
	-- Percent changes at ~1%/min at best, so 30s is plenty; the events below
	-- make the AC↔battery swap and wake instantly.
	update_freq = 30,
})

-- Only (re)start the charging pulse animation on the AC↔battery transition
-- instead of every poll — the property persists, so one sketchybar call per
-- charge session is enough.
local prev_charging = false

battery:subscribe({ "routine", "power_source_change", "system_woke", "brightness_change" }, function()
	-- Raw state comes from the shared file (/tmp/status/batt: charging|pct|status)
	-- written by the launchd status daemon, instead of running pmset from sketchybar.
	local out = read_file("/tmp/status/batt") or ""
	local icon = "!"
	local label = "?"
	local charging = false

	local c, charge, status = out:match("^(%d)|(%d+)|([^|]*)$")
	if c then
		charging = c == "1"
		charge = tonumber(charge)
		label = charge .. "%"
	end

	local color
	if charging then
		icon = icons.battery.charging
		color = colors.accent
	elseif c and charge > 60 then
		icon = icons.battery._100
		color = colors.accent
	elseif c and charge > 40 then
		icon = icons.battery._75
		color = colors.gold
	elseif c and charge > 20 then
		icon = icons.battery._50
		color = colors.orange
	elseif c and charge > 10 then
		icon = icons.battery._25
		color = colors.orange
	else
		icon = icons.battery._0
		color = colors.love
	end

	local lead = (c and charge < 10) and "0" or ""

	battery:set({
		icon = { string = icon, color = color },
		label = { string = lead .. label },
	})

	if charging and not prev_charging then
		sbar.exec("sketchybar --set " .. battery.name .. " icon.symbol_anim=pulse")
	end
	prev_charging = charging
end)
