local colors = require("colors")
local settings = require("settings")

-- Caffeine/Amphetamine toggle: keeps the system awake via `caffeinate -id`.
-- Click toggles it; the icon reflects whether a caffeinate assertion is active.
-- The periodic assertion check reads the shared raw state (/tmp/status/
-- caffeinate, PID written by the launchd status daemon). The click handler
-- still queries pmset directly for an accurate toggle.

local ICON_INIT = utf8.char(0xF410)
local ICON_IDLE = utf8.char(0xEC15)
local ICON_ACTIVE = utf8.char(0xEF59)

local GET_ID = "pmset -g assertions | grep caffeinate | awk '{print $2}' | cut -d '(' -f1 | head -n 1"

local caffeinate = sbar.add("item", "widgets.caffeinate", {
	position = "left",
	update_freq = 30,
	icon = {
		string = ICON_INIT,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 17.0,
		},
		color = colors.white,
		padding_left = 9,
		padding_right = 7,
		y_offset = 1.5,
	},
	label = { drawing = false },
})

local function refresh()
	local out = read_file("/tmp/status/caffeinate") or ""
	local active = out:match("[0-9]+") ~= nil
	caffeinate:set({ icon = { string = active and ICON_ACTIVE or ICON_IDLE } })
end

caffeinate:subscribe({ "routine", "forced" }, refresh)

caffeinate:subscribe("mouse.clicked", function()
	sbar.exec(GET_ID, function(out)
		local pid = (out or ""):match("[0-9]+")
		if pid then
			sbar.exec("kill -9 " .. pid)
			caffeinate:set({ icon = { string = ICON_IDLE } })
		else
			sbar.exec("caffeinate -id &")
			caffeinate:set({ icon = { string = ICON_ACTIVE } })
		end
	end)
end)

refresh()
