local colors = require("colors")
local settings = require("settings")

-- Bluetooth widget mirroring ~/.config/tmux/scripts/bluetooth.sh.
-- blueutil 2.13.0's --connected is broken on macOS 14+ (returns empty), so
-- connection state is derived per-device via `blueutil --info` + ", connected".
-- Icon: device-type glyph of the primary connected device; label = device
-- name(s) (+ battery). Left-click opens a popup listing paired devices
-- (click to connect/disconnect) plus power + settings entries.

local BLUETOOTH = "widgets.bluetooth"
local POPUP_PREFIX = "widgets.bluetooth.popup."
local POPUP_WIDTH = 250

local ICON_OFF = "󰂲"
local ICON_ON = "󰂯"

local TYPE_ICONS = {
	headphone = "󰋋",
	keyboard = "",
	mouse = "",
	speaker = "󰓃",
	phone = "󰀲",
	trackpad = "",
	watch = "󰖉",
	tablet = "󰩼",
	gamepad = "",
	printer = "󰐪",
	generic = "󰂯",
}

local function detect_type(name)
	local lower = name:lower()
	if lower:find("buds") or lower:find("ear") or lower:find("headphone") or lower:find("headset") then
		return "headphone"
	end
	if lower:find("keyboard") or lower:find("keys") then
		return "keyboard"
	end
	if lower:find("mouse") then
		return "mouse"
	end
	if lower:find("speaker") or lower:find("speak") then
		return "speaker"
	end
	if lower:find("phone") or lower:find("iphone") or lower:find("galaxy") or lower:find("pixel") then
		return "phone"
	end
	if lower:find("trackpad") then
		return "trackpad"
	end
	if lower:find("watch") then
		return "watch"
	end
	if lower:find("tablet") or lower:find("ipad") then
		return "tablet"
	end
	if lower:find("gamepad") or lower:find("joystick") or lower:find("controller") then
		return "gamepad"
	end
	if lower:find("printer") then
		return "printer"
	end
	return "generic"
end

-- Per-device connection check (the --connected workaround). Emits one line per
-- unique paired device: addr|name|connected|battery
local DEVICES_CMD = [[
blueutil -p 2>/dev/null
echo '---'
blueutil --paired 2>/dev/null | grep -oE 'address: [0-9a-fA-F-]+' | awk '{print $2}' | sort -u | while read -r addr; do
	info=$(blueutil --info "$addr" 2>/dev/null)
	name=$(printf '%s' "$info" | sed -n 's/.*name: "\([^"]*\)".*/\1/p')
	[ -z "$name" ] && continue
	if printf '%s' "$info" | grep -q ', connected'; then conn='1'; else conn='0'; fi
	bat=$(pmset -g accps 2>/dev/null | grep -F "$name" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
	[ -n "$bat" ] || bat=$(printf '%s' "$info" | grep -i battery | grep -oE '[0-9]+' | head -1)
	echo "$addr|$name|$conn|${bat:-}"
done
]]

local bluetooth = sbar.add("item", BLUETOOTH, {
	position = "center",
	scroll_texts = false,
	icon = {
		string = ICON_OFF,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Regular"],
			size = 15.0,
		},
		color = colors.grey,
		padding_left = 11,
		padding_right = 4,
	},
	label = {
		string = "",
		drawing = false,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 12,
		},
		color = colors.white,
		padding_right = 8,
	},
	popup = {
		align = "right",
		blur_radius = 50,
		height = 20,
		background = {
			color = colors.popup.bg,
			corner_radius = 9,
			border_width = 1,
			border_color = colors.popup.border,
		},
	},
	updates = true,
	update_freq = 10,
})

local function fetch_state(cb)
	sbar.exec(DEVICES_CMD, function(out)
		local power_line, rest = (out or ""):match("^([01])\n%-%-%-%-?(.*)$")
		if not power_line then
			cb(nil, {})
			return
		end
		local devices = {}
		for line in (rest or ""):gmatch("[^\r\n]+") do
			local addr, name, conn, bat = line:match("^([^|]+)|([^|]*)|([01])|([^|]*)$")
			if addr and name and name ~= "" then
				devices[#devices + 1] = {
					addr = addr,
					name = name,
					connected = conn == "1",
					battery = bat,
				}
			end
		end
		cb(power_line == "1", devices)
	end)
end

local function apply_bar(on, devices)
	local connected = {}
	for _, d in ipairs(devices) do
		if d.connected then
			connected[#connected + 1] = d
		end
	end

	local glyph, color, text
	if not on then
		glyph, color, text = ICON_OFF, colors.grey, ""
	elseif #connected == 0 then
		glyph, color, text = ICON_ON, colors.white, ""
	else
		local primary = connected[1]
		glyph = TYPE_ICONS[detect_type(primary.name)]
		color = colors.gold
		if #connected == 1 then
			text = primary.name
			if primary.battery and primary.battery ~= "" then
				text = text .. " (" .. primary.battery .. "%)"
			end
		else
			text = primary.name .. " +" .. (#connected - 1)
		end
	end

	bluetooth:set({
		icon = { string = glyph, color = color },
		label = { string = text, drawing = text ~= "" },
	})

	-- The bluetooth label width can change the center block's recenter, which
	-- shrinks/grows the room the media title has before the notch.
	sbar.trigger("media_space_changed")
end

local function remove_popup_items()
	sbar.remove("/" .. POPUP_PREFIX:gsub("%.", "\\.") .. ".*/")
end

local popup_open = false

-- Forward-declared so the popup click handlers below can rebuild on demand.
local refresh
-- Cache of the last rendered device state; reset on close so reopening rebuilds.
local device_key = ""

local function close_popup()
	popup_open = false
	device_key = ""
	bluetooth:set({ popup = { drawing = false } })
	remove_popup_items()
end

local function build_popup(on, devices)
	remove_popup_items()

	local added = false
	for _, d in ipairs(devices) do
		added = true
		local row = sbar.add("item", POPUP_PREFIX .. "dev." .. d.addr:gsub("[^%w]", "-"), {
			position = "popup." .. BLUETOOTH,
			width = POPUP_WIDTH,
			align = "center",
			background = {
				height = 20,
				color = colors.transparent,
				border_width = 0,
			},
			icon = {
				string = TYPE_ICONS[detect_type(d.name)],
				font = {
					family = settings.font.text,
					style = settings.font.style_map["Regular"],
					size = 13.0,
				},
				color = d.connected and colors.accent or colors.grey,
				padding_left = 10,
				padding_right = 6,
			},
			label = {
				string = d.name .. (d.connected and d.battery ~= "" and (" (" .. d.battery .. "%)") or ""),
				font = {
					family = settings.font.text,
					style = settings.font.style_map["Bold"],
					size = 12,
				},
				color = d.connected and colors.white or colors.with_alpha(colors.white, 0.55),
				padding_right = 10,
			},
		})
		row:subscribe("mouse.clicked", function()
			local verb = d.connected and "disconnect" or "connect"
			sbar.exec("blueutil --" .. verb .. " " .. d.addr, function()
				refresh(true)
			end)
		end)
	end

	if not added then
		sbar.add("item", POPUP_PREFIX .. "none", {
			position = "popup." .. BLUETOOTH,
			width = POPUP_WIDTH,
			align = "center",
			background = {
				height = 20,
				color = colors.transparent,
				border_width = 0,
			},
			label = {
				string = "No paired devices",
				font = {
					family = settings.font.text,
					style = settings.font.style_map["Bold"],
					size = 12,
				},
				color = colors.with_alpha(colors.white, 0.55),
			},
		})
	end

	sbar.add("item", POPUP_PREFIX .. "sep", {
		position = "popup." .. BLUETOOTH,
		width = POPUP_WIDTH,
		icon = { drawing = false },
		label = { drawing = false },
		background = { height = 1, color = colors.popup.border },
	})

	local power = sbar.add("item", POPUP_PREFIX .. "power", {
		position = "popup." .. BLUETOOTH,
		width = POPUP_WIDTH,
		align = "center",
		background = {
			height = 20,
			color = colors.transparent,
			border_width = 0,
		},
		icon = {
			string = on and ICON_ON or ICON_OFF,
			font = {
				family = settings.font.text,
				style = settings.font.style_map["Regular"],
				size = 13.0,
			},
			color = colors.accent,
			padding_left = 10,
			padding_right = 6,
		},
		label = {
			string = "Bluetooth " .. (on and "On" or "Off"),
			font = {
				family = settings.font.text,
				style = settings.font.style_map["Bold"],
				size = 12,
			},
			color = colors.accent,
			padding_right = 10,
		},
	})
	power:subscribe("mouse.clicked", function()
		sbar.exec("blueutil -p toggle", function()
			refresh(true)
		end)
	end)

	local prefs = sbar.add("item", POPUP_PREFIX .. "prefs", {
		position = "popup." .. BLUETOOTH,
		width = POPUP_WIDTH,
		align = "center",
		background = {
			height = 20,
			color = colors.transparent,
			border_width = 0,
		},
		icon = {
			string = "",
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
			string = "Bluetooth Settings…",
			font = {
				family = settings.font.text,
				style = settings.font.style_map["Bold"],
				size = 12,
			},
			color = colors.with_alpha(colors.white, 0.55),
			padding_right = 10,
		},
	})
	prefs:subscribe("mouse.clicked", function()
		sbar.exec("open x-apple.systempreferences:com.apple.BluetoothSettings")
		close_popup()
	end)
end

refresh = function(rebuild_popup)
	fetch_state(function(on, devices)
		apply_bar(on, devices)
		local key = (on and "1" or "0")
		for _, d in ipairs(devices) do
			key = key .. "|" .. d.addr .. d.name .. (d.connected and "1" or "0") .. d.battery
		end
		if rebuild_popup and key ~= device_key then
			device_key = key
			build_popup(on, devices)
		end
	end)
end

local function toggle_popup()
	if popup_open then
		close_popup()
	else
		popup_open = true
		bluetooth:set({ popup = { drawing = true } })
		refresh(true)
	end
end

bluetooth:subscribe("mouse.clicked", function(env)
	if env.BUTTON == "right" then
		sbar.exec("open x-apple.systempreferences:com.apple.BluetoothSettings")
	else
		toggle_popup()
	end
end)

bluetooth:subscribe("mouse.exited.global", close_popup)

bluetooth:subscribe({ "routine", "system_woke", "forced" }, function()
	refresh(false)
end)

-- Fires immediately when a bluetooth device connects/disconnects.
sbar.add("event", "bluetooth_status", "com.apple.bluetooth.status")
bluetooth:subscribe("bluetooth_status", function()
	refresh(popup_open)
end)

refresh(false)
