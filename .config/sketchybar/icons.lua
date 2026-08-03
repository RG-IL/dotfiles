local settings = require("settings")

local icons = {
	sf_symbols = {
		plus = "􀅼",
		loading = "􀖇",
		apple = "􀣺",
		gear = "􀍟",
		cpu = "􀫥",
		memory = "􀫦",
		disk = "􀤂",
		clipboard = "􀉄",

		switch = {
			on = "􁏮",
			off = "􁏯",
		},
		volume = {
			_100 = "􀊩",
			_66 = "􀊧",
			_33 = "􀊥",
			_10 = "􀊡",
			_0 = "􀊣",
		},
		battery = {
			_100 = "􀛨",
			_75 = "􀺸",
			_50 = "􀺶",
			_25 = "􀛩",
			_0 = "􀛪",
			charging = "􀢋",
		},
		wifi = {
			upload = "􀄨",
			download = "􀄩",
			connected = "􀙇",
			disconnected = "􀙈",
			router = "􁓤",
		},
		ethernet = "󰈀",
		media = {
			back = "􀊊",
			forward = "􀊌",
			play_pause = "􀊈",
			play = "􀊃",
			pause = "􀊆",
		},
	},

	-- Alternative NerdFont icons
	nerdfont = {
		plus = "",
		loading = "",
		apple = "",
		gear = "",
		cpu = "",
		memory = "",
		disk = "󰋊",
		clipboard = "󰆏",

		switch = {
			on = "󱨥",
			off = "󱨦",
		},
		volume = {
			_100 = "",
			_66 = "",
			_33 = "",
			_10 = "",
			_0 = "",
		},
		battery = {
			_100 = "",
			_75 = "",
			_50 = "",
			_25 = "",
			_0 = "",
			charging = "",
		},
		wifi = {
			upload = "",
			download = "",
			connected = "󰖩",
			disconnected = "󰖪",
			router = "󰑩",
		},
		network = {
			up = "",
			down = "",
		},
		chevron = {
			right = "",
			left = "",
		},
		ethernet = "󰈀",
		media = {
			back = "",
			forward = "",
			play_pause = "",
			play = "",
			pause = "",
		},
	},
}

if not (settings.icons == "NerdFont") then
	return icons.sf_symbols
else
	return icons.nerdfont
end
