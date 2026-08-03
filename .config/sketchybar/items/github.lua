local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

local github_bell = sbar.add("item", "github.bell", {
	position = "left",
	associated_space = 1,
	update_freq = 60,
	icon = {
		string = "",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 15.0,
		},
		color = colors.white,
	},
	label = {
		string = icons.loading,
		drawing = false,
	},
	script = "$CONFIG_DIR/items/apple.sh",
	click_script = "sketchybar --set $NAME popup.drawing=toggle",
})

return github_bell
