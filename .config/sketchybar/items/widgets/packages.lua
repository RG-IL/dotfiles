local settings = require("settings")

-- Brew outdated-packages counter driven entirely by items/package_monitor.sh.
-- update_freq makes sketchybar run the script every 5 min with $SENDER=routine;
-- the script counts `brew outdated` and color-codes the icon (see colors.sh).

sbar.add("item", "widgets.packages", {
	position = "right",
	scroll_texts = false,
	script = "$CONFIG_DIR/items/package_monitor.sh",
	icon = {
		string = "󰏗",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Regular"],
			size = 14.0,
		},
		padding_left = 8,
		padding_right = 4,
	},
	label = {
		string = "",
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 12.0,
		},
		padding_right = 8,
	},
	update_freq = 300,
})

-- React to `brew upgrade` run in the terminal: a ~/.zshrc brew() wrapper fires
-- the brew_upgrade event after upgrading. CLI --subscribe (via sbar.exec) instead
-- of the Lua subscribe() binding, because the binding overwrites `script` with an
-- empty value and a mach helper. `--add event` is idempotent, so re-running on
-- every reload is safe. The sleep defers past the config rebuild, which would
-- otherwise clobber the update_mask set by this message.
sbar.exec("sleep 2; sketchybar -m --add event brew_upgrade; sketchybar -m --subscribe widgets.packages brew_upgrade")
