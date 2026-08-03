local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Wi-Fi indicator with a hover popup showing the tx rate. Uses a Nerd Font
-- glyph (not a Control Center alias) so it renders without Screen Recording
-- permission. SSID is redacted on macOS 26+, so the popup only reports the
-- transmit rate from the CoreWLAN helper.

local WIFI = "widgets.wifi"
local WIFI_FILE = "/tmp/status/wifi"

local wifi = sbar.add("item", WIFI, {
	position = "right",
	padding_right = 0,
	icon = {
		string = icons.wifi.connected,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Regular"],
			size = 17.0,
		},
		color = colors.accent,
		padding_left = 8,
		padding_right = 3,
	},
	label = { drawing = false },
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
	update_freq = 1,
})

local details = sbar.add("item", "wifi.details", {
	position = "popup." .. WIFI,
	icon = { drawing = false },
	label = {
		string = "…",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 12,
		},
		color = colors.white,
		align = "center",
		padding_left = 10,
		padding_right = 10,
	},
	click_script = "sketchybar --set " .. WIFI .. " popup.drawing=off",
})

local function update()
	-- Transmit rate comes from the shared raw state (/tmp/status/wifi field 3:
	-- ssid|signal|rate) written by the launchd status daemon, instead of
	-- running the CoreWLAN helper from sketchybar.
	sbar.exec("cat " .. WIFI_FILE, function(out)
		local rate = (out or ""):match("^[^|]*|[^|]*|([0-9]*)")
		if rate and rate ~= "" then
			details:set({
				label = { string = "Connected · " .. rate .. " Mbps" },
			})
			wifi:set({
				icon = { string = icons.wifi.connected, color = colors.accent },
			})
		else
			details:set({ label = { string = "N/A" } })
			wifi:set({
				icon = { string = icons.wifi.disconnected, color = colors.grey },
			})
		end
	end)
end

wifi:subscribe({ "routine", "forced" }, update)

wifi:subscribe("mouse.entered", function()
	update()
	wifi:set({ popup = { drawing = true } })
end)
wifi:subscribe({ "mouse.exited", "mouse.exited.global" }, function()
	wifi:set({ popup = { drawing = false } })
end)
wifi:subscribe("mouse.clicked", function()
	update()
	wifi:set({ popup = { drawing = "toggle" } })
end)

update()
