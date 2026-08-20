local colors = require("colors")
local settings = require("settings")
local icons = require("icons")

-- For position="center", earlier-added items render to the LEFT.
-- Bar layout: playpause → artwork → title

local playpause = sbar.add("item", "center.media.playpause", {
	position = "center",
	icon = {
		string = icons.media.play,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 15,
		},
		color = colors.with_alpha(colors.accent, 0.45),
		padding_left = 4,
		padding_right = 4,
	},
	label = { drawing = false },
})

local artwork = sbar.add("item", "center.media.artwork", {
	position = "center",
	background = {
		image = {
			string = "",
			scale = 0.23,
			corner_radius = 4,
		},
		color = colors.transparent,
		border_width = 0,
		height = 22,
		corner_radius = 4,
	},
	icon = { drawing = false },
	label = { drawing = false },
	drawing = false,
	padding_left = 2,
	padding_right = 2,
	y_offset = -1,
})

local media = sbar.add("item", "center.media", {
	position = "center",
	icon = { drawing = false },
	scroll_texts = false,
	label = {
		string = "It's pretty silent",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 12,
		},
		-- color = colors.with_alpha(colors.white, 0.30),
		color = colors.white,
		padding_left = 4,
		padding_right = 4,
	},
	popup = {
		align = "center",
		horizontal = true,
		background = {
			color = colors.popup.bg,
			corner_radius = 9,
			border_width = 1,
			border_color = colors.popup.border,
			height = 56,
		},
	},
	update_freq = 30,
	updates = true,
})

local popup_artwork = sbar.add("item", "popup.center.media.art", {
	position = "popup.center.media",
	background = {
		image = { string = "", scale = 0.5, corner_radius = 6 },
		color = colors.transparent,
		border_width = 0,
		height = 48,
		corner_radius = 6,
	},
	icon = { drawing = false },
	label = { drawing = false },
	drawing = false,
	padding_left = 10,
	padding_right = 6,
})

local popup_title = sbar.add("item", "popup.center.media.title", {
	position = "popup.center.media",
	icon = { drawing = false },
	label = {
		string = "",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 13,
		},
		color = 0xffffffff,
		padding_left = 4,
		padding_right = 4,
	},
})

local popup_artist = sbar.add("item", "popup.center.media.artist", {
	position = "popup.center.media",
	icon = { drawing = false },
	label = {
		string = "",
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 12,
		},
		color = colors.with_alpha(colors.white, 0.55),
		padding_left = 2,
		padding_right = 10,
	},
})

local popup_prev = sbar.add("item", "popup.center.media.prev", {
	position = "popup.center.media",
	icon = {
		string = icons.media.back,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14,
		},
		color = colors.with_alpha(colors.accent, 0.85),
		padding_left = 12,
		padding_right = 8,
	},
	label = { drawing = false },
})
local popup_playpause = sbar.add("item", "popup.center.media.playpause", {
	position = "popup.center.media",
	icon = {
		string = icons.media.play,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14,
		},
		color = colors.accent,
		padding_left = 8,
		padding_right = 8,
	},
	label = { drawing = false },
})

local popup_next = sbar.add("item", "popup.center.media.next", {
	position = "popup.center.media",
	icon = {
		string = icons.media.forward,
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14,
		},
		color = colors.with_alpha(colors.accent, 0.85),
		padding_left = 8,
		padding_right = 12,
	},
	label = { drawing = false },
})

local current_track_key = nil
local artwork_counter = 0
local last_label_state = nil
local last_play_state = nil

-- Geometry only changes when the media label, play state, artwork, the
-- bluetooth label, or the left bracket (spaces) resize — so the expensive
-- re-measure (geom.py + several sketchybar queries) runs only on those events,
-- not on every poll.
local budget_pending = false
local budget_running = false
local schedule_budget

local SHOW_ARTWORK = true
local MAX_LABEL_CHARS = SHOW_ARTWORK and 20 or 24

-- Dynamic label budget: the title tracks the bluetooth label width so the
-- notch item stays fixed over the hardware cutout. A longer bluetooth name
-- pushes the notch left, so the title grows to push it back (and shrinks when
-- the bluetooth label shortens). The text is adjusted (truncated/padded), the
-- notch position is preserved, and SAFETY_PX of headroom is kept before the
-- left bracket.
local MIN_LABEL_CHARS = 8
local MAX_LABEL_LIMIT = 44
local CHAR_ADV = 7.15 -- px per display column (JetBrainsMono Nerd Font SemiBold 12)
local SAFETY_PX = 12 -- minimum gap kept between the media pill and bracket.left
local MEDIA_PAD_PX = 8 -- center.media label padding_left + padding_right

-- Emits "notch_left notch_width playpause_x bracket_right media_width
-- right_bracket_right": the notch spacer's left edge and width, the play/pause
-- item's left edge, the right edge of the left bracket pill, the width of the
-- media title item, and the right edge of the right bracket pill.
-- Parsed with a regex (not json.loads) because sketchybar emits unescaped
-- quotes in label values, which makes the item JSON invalid (e.g. a title
-- containing a double quote breaks the whole budget update).
local GEOM_CMD = [[/usr/bin/python3 "$HOME/.config/sketchybar/items/geom.py"]]

-- Right margin of the bar (bar.lua "margin"); the right bracket is anchored this
-- far from the display's right edge, so display_width = right edge + margin.
local MARGIN_RIGHT = 64

-- East-Asian "wide" codepoints (CJK, Hiragana/Katakana, Hangul, full-width
-- forms, …) render at roughly double the advance of a Latin glyph, so budget
-- the label by display columns rather than raw character count — otherwise a
-- Japanese title with the same character count is ~2x wider and overflows the
-- notch / grows the center pill.
local function char_width(cp)
	if
		(cp >= 0x1100 and cp <= 0x115F) -- Hangul Jamo
		or (cp >= 0x2E80 and cp <= 0x303E) -- CJK radicals, Kangxi, punctuation
		or (cp >= 0x3041 and cp <= 0x33FF) -- Hiragana, Katakana, CJK symbols
		or (cp >= 0x3400 and cp <= 0x4DBF) -- CJK Ext A
		or (cp >= 0x4E00 and cp <= 0x9FFF) -- CJK Unified
		or (cp >= 0xA000 and cp <= 0xA4CF) -- Yi
		or (cp >= 0xAC00 and cp <= 0xD7A3) -- Hangul syllables
		or (cp >= 0xF900 and cp <= 0xFAFF) -- CJK compatibility
		or (cp >= 0xFE30 and cp <= 0xFE4F) -- CJK compatibility forms
		or (cp >= 0xFF00 and cp <= 0xFF60) -- Fullwidth forms
		or (cp >= 0xFFE0 and cp <= 0xFFE6) -- Fullwidth signs
		or (cp >= 0x20000 and cp <= 0x3FFFD) -- CJK Ext B+
	then
		return 2
	end
	return 1
end

local function display_width(s)
	local w = 0
	for _, cp in utf8.codes(s) do
		w = w + char_width(cp)
	end
	return w
end

local function truncate(s, n)
	if display_width(s) <= n then
		return s
	end
	-- Reserve one column for the ellipsis.
	local budget = n - 1
	local w = 0
	local out = {}
	for _, cp in utf8.codes(s) do
		local cw = char_width(cp)
		if w + cw > budget then
			break
		end
		w = w + cw
		out[#out + 1] = utf8.char(cp)
	end
	return table.concat(out) .. "…"
end

-- U+2003 EM SPACE — invisible, ~"M"-width, so short titles still hold
-- close to the full pill width and the center pill stops shifting.
local PAD_CHAR = "\xe2\x80\x83"

local function pad_to(s, n)
	local w = display_width(s)
	if w < n then
		return s .. string.rep(PAD_CHAR, n - w)
	end
	return s
end

local function update_track_info(title, artist)
	local key = (title or "") .. "|" .. (artist or "")
	if key == current_track_key then
		return
	end
	current_track_key = key

	-- Artwork appears/disappears here, shifting the center block; re-measure.
	schedule_budget()

	popup_title:set({ label = { string = title or "" } })
	popup_artist:set({ label = { string = artist or "" } })

	artwork_counter = artwork_counter + 1
	local path = string.format("/tmp/sketchybar_art_%d.jpg", artwork_counter)
	local cmd = string.format(
		"nowplaying-cli get artworkData 2>/dev/null | base64 -D > %q 2>/dev/null; "
			.. "if [ -s %q ]; then sips -Z 96 %q >/dev/null 2>&1; echo ok; else rm -f %q; fi",
		path,
		path,
		path,
		path
	)
	sbar.exec(cmd, function(out)
		if current_track_key ~= key then
			return
		end
		if out and out:match("ok") then
			if SHOW_ARTWORK then
				artwork:set({
					drawing = true,
					background = { image = { drawing = true, string = path } },
					icon = { drawing = false },
				})
			end
			popup_artwork:set({
				drawing = true,
				background = { image = { drawing = true, string = path } },
			})
		else
			artwork:set({ drawing = false })
			popup_artwork:set({ drawing = false })
		end
		-- The artwork width landed async, after the budget may have measured;
		-- re-measure so the notch stays pinned.
		schedule_budget()
	end)
end

local function show_idle_artwork()
	if not SHOW_ARTWORK then
		artwork:set({ drawing = false })
		return
	end
	artwork:set({
		drawing = true,
		background = { image = { drawing = false } },
		icon = {
			drawing = true,
			string = ":music:",
			font = {
				family = "sketchybar-app-font",
				style = "Regular",
				size = 14.0,
			},
			color = colors.with_alpha(colors.accent, 0.45),
			padding_left = 4,
			padding_right = 4,
		},
	})
end

local function clear_track_info()
	current_track_key = nil
	show_idle_artwork()
	popup_artwork:set({ drawing = false })
	popup_title:set({ label = { string = "" } })
	popup_artist:set({ label = { string = "" } })
end

local function set_play_icon(playing)
	if playing == last_play_state then
		return
	end
	last_play_state = playing
	-- The play/pause glyph swap can shift the pill by a pixel; re-measure.
	schedule_budget()
	local glyph = playing and icons.media.pause or icons.media.play
	local color = playing and colors.accent or colors.with_alpha(colors.accent, 0.45)
	playpause:set({ icon = { string = glyph, color = color } })
	popup_playpause:set({ icon = { string = glyph } })
end

local function set_label(text, faded, animate)
	text = pad_to(truncate(text, MAX_LABEL_CHARS), MAX_LABEL_CHARS)
	local key = (faded and "f|" or "n|") .. text
	if key == last_label_state then
		return
	end
	last_label_state = key
	-- The title width (and thus the recenter) changed; re-measure.
	schedule_budget()
	local color = faded and colors.with_alpha(colors.white, faded) or 0xffffffff
	if animate then
		sbar.animate("tanh", 10, function()
			media:set({ label = { string = text, color = color } })
		end)
	else
		media:set({ label = { string = text, color = color } })
	end
end

-- Last rendered state, so the label can be re-applied when the char budget
-- changes without re-querying nowplaying.
local state_idle = true
local state_title, state_artist = "", ""
local state_playing = false

local function set_idle()
	state_idle = true
	clear_track_info()
	set_play_icon(false)
	set_label("It's pretty silent in here...", 0.5, true)
end

local function set_track(title, artist, playing)
	state_idle = false
	state_title, state_artist, state_playing = title, artist, playing

	local display = truncate(title .. (artist ~= "" and (" – " .. artist) or ""), MAX_LABEL_CHARS)

	update_track_info(title, artist)
	set_play_icon(playing)
	set_label(display, not playing and 0.5 or false, true)
end

local function render_state()
	if state_idle then
		set_idle()
	else
		set_track(state_title, state_artist, state_playing)
	end
end

-- Pins the notch spacer over the hardware cutout by growing/shrinking the
-- title budget: the center block recenters as a whole, so a bluetooth label
-- change pushes the notch off the cutout, and the title pushes it back by the
-- same amount (a ΔT label change moves the notch by ΔT/2, hence the ×2).
-- The budget is also capped so the pill keeps SAFETY_PX before bracket.left.
local function update_char_budget()
	-- Let the animated label settle before reading geometry, so the notch
	-- displacement is measured at its final (not mid-animation) position.
	sbar.exec("sleep 0.4 && " .. GEOM_CMD, function(out)
		budget_running = false
		if budget_pending then
			budget_pending = false
			schedule_budget()
			return
		end
		local nl, nw, px, br, mdw, brr = (out or ""):match(
			"(-?%d+%.?%d*)%s+(-?%d+%.?%d*)%s+(-?%d+%.?%d*)%s+(-?%d+%.?%d*)%s+(-?%d+%.?%d*)%s+(-?%d+%.?%d*)"
		)
		if not (nl and nw and px and br and mdw and brr) then
			return
		end
		local notch_left = tonumber(nl)
		local notch_width = tonumber(nw)
		local playpause_x = tonumber(px)
		local bracket_right = tonumber(br)
		local media_width = tonumber(mdw)
		local right_bracket_right = tonumber(brr)

		-- The hardware cutout is centered on the display; the right bracket is
		-- anchored MARGIN_RIGHT from the display's right edge.
		local screen_center = (right_bracket_right + MARGIN_RIGHT) / 2
		local desired_notch_left = screen_center - notch_width / 2
		local dN = desired_notch_left - notch_left

		local target_width = media_width - MEDIA_PAD_PX + 2 * dN
		local target_chars = math.floor(target_width / CHAR_ADV)
		if target_chars < MIN_LABEL_CHARS then
			target_chars = MIN_LABEL_CHARS
		elseif target_chars > MAX_LABEL_LIMIT then
			target_chars = MAX_LABEL_LIMIT
		end

		-- Growing the label shifts the whole block left by ΔT/2; cap the
		-- budget so the pill keeps SAFETY_PX of gap before bracket.left.
		local max_grow = 2 * (playpause_x - bracket_right - SAFETY_PX)
		local capped = math.floor((media_width - MEDIA_PAD_PX + max_grow) / CHAR_ADV)
		if capped < target_chars then
			target_chars = capped
		end
		if target_chars < MIN_LABEL_CHARS then
			target_chars = MIN_LABEL_CHARS
		end

		if target_chars ~= MAX_LABEL_CHARS then
			MAX_LABEL_CHARS = target_chars
			render_state()
		end
	end)
end

-- Coalesces budget re-measures: starts one if none is in flight, otherwise
-- marks the change pending so the in-flight measurement re-runs once it lands.
-- (The render_state→set_label→schedule_budget path also converges: each run
-- re-measures the settled geometry and only re-schedules while the budget is
-- still moving.)
schedule_budget = function()
	if budget_running then
		budget_pending = true
		return
	end
	budget_running = true
	update_char_budget()
end

local function toggle_popup()
	media:set({ popup = { drawing = "toggle" } })
end

-- On macOS 15.4+ the native `media_change` event no longer fires (Apple locked
-- MediaRemote), so helpers/media_watch.sh drives updates via the custom
-- media_update event: it runs `media-control stream`, merges the payload into
-- /tmp/status/media (<playing:0|1>|<title>|<artist>), and triggers. The stream
-- is the authoritative state — it fires ~60-150ms after a change, whereas
-- re-querying the daemon (nowplaying-cli) returns STALE state for ~1s after a
-- pause. The widget renders ONLY from this file. `update_freq` re-reads the
-- file on a slow cadence as a free watchdog in case the watcher ever dies; it
-- never touches the daemon, so it can't be stale and costs ~0 CPU.
local function render_from_state()
	local text = (read_file("/tmp/status/media") or ""):gsub("%s+$", "")
	local playing, title, artist = text:match("^([^|]+)|([^|]*)|([^|]*)$")
	local is_playing = playing == "1" or playing == "true"
	if title and title ~= "" then
		set_track(title, artist or "", is_playing)
	else
		set_idle()
	end
end

media:subscribe("routine", render_from_state)
media:subscribe("media_update", render_from_state)
media:subscribe("system_woke", function()
	schedule_budget()
	render_from_state()
end)
-- The bluetooth label width recenters the whole center block; re-measure so
-- the title budget pushes the notch back over the cutout.
media:subscribe("media_space_changed", function()
	schedule_budget()
	render_from_state()
end)
media:subscribe("mouse.clicked", toggle_popup)
artwork:subscribe("mouse.clicked", toggle_popup)

local function optimistic_toggle()
	-- Flip the glyph immediately; the watcher's media_update confirms and
	-- corrects within ~100ms if the media-control stream line disagrees.
	if last_play_state ~= nil then
		local now_playing = not last_play_state
		set_play_icon(now_playing)
		if last_label_state then
			local text = last_label_state:sub(3)
			last_label_state = nil
			set_label(text, not now_playing and 0.45 or false, false)
		end
	end
	sbar.exec("nowplaying-cli togglePlayPause")
end

playpause:subscribe("mouse.clicked", optimistic_toggle)
popup_playpause:subscribe("mouse.clicked", optimistic_toggle)
-- prev/next just run the command; the media_update event re-renders the new
-- track when the stream emits it.
popup_prev:subscribe("mouse.clicked", function()
	sbar.exec("nowplaying-cli previous")
end)
popup_next:subscribe("mouse.clicked", function()
	sbar.exec("nowplaying-cli next")
end)

media:subscribe("mouse.exited.global", function()
	media:set({ popup = { drawing = false } })
end)

-- Drive instant updates from helpers/media_watch.sh (macOS 15.4+ killed the
-- native media_change event). `--add event` is idempotent, so re-running on
-- reload is safe; the watcher guards itself against duplicate spawns.
sbar.add("event", "media_update")
sbar.exec("nohup $CONFIG_DIR/helpers/media_watch.sh >/dev/null 2>&1 &")

render_from_state()
