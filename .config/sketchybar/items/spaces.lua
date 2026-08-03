local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Window manager backend. Swap to spaces_aerospace / spaces_omniwm and restart
-- sketchybar to switch. All modules expose: events, list_workspaces_cmd(),
-- fetch_state_cmd(), click_cmd(id), display_label(id).
local backend = require("items.spaces_aerospace")
-- local backend = require("items.spaces_omniwm")

sbar.add("event", "aerospace_workspace_change")

-- Horizontal padding (in px) on each side of a space pill. Tweak to change pill widths.
local pill_padding = {
	inactive = 6, -- not focused (no background, just number + icons)
	active_empty = 24, -- focused workspace with no apps
	active_icons = 18, -- focused workspace with apps (padding around the app icons)
}

-- Gap between the workspace number and the app icons in a focused-with-apps pill.
local number_icon_gap = 6

local function exec_to_table(cmd)
	local handle = io.popen(cmd)
	if not handle then
		return {}
	end
	local result = handle:read("*a")
	handle:close()
	local lines = {}
	for line in result:gmatch("[^\n]+") do
		lines[#lines + 1] = line
	end
	return lines
end

local space_items = {}
local space_names = {}
local space_state = {}
local space_drawn = {}
-- Coalesce rapid events: if an update arrives while one is in-flight, mark
-- dirty and re-run after — never drop. Dropping caused the bracket to settle
-- to a stale state on rapid switches; overlapping animations on top of that
-- caused the pill bg to flicker mid-resize.
-- Timestamped instead of boolean so a lost sbar.exec callback can't strand
-- the lock; after LOCK_TIMEOUT_S the next event proceeds anyway.
local update_in_flight_at = 0
local update_dirty = false
local LOCK_TIMEOUT_S = 3

	local function build_space_set(icons, selected, ws_label)
	local has_icons = icons ~= ""
	local should_draw = selected or has_icons
	local show_number = ws_label ~= nil and ws_label ~= ""

	local pad
	if not selected then
		pad = pill_padding.inactive
	elseif has_icons then
		pad = pill_padding.active_icons
	else
		pad = pill_padding.active_empty
	end

	-- Non-focused spaces sit directly on the bracket's translucent pill, so
	-- use light text; the focused space sits on the accent pill and needs
	-- dark text to stay readable.
	local text_color = selected and colors.base or colors.white

	-- The space character between glyphs has different vertical metrics
	-- than the app icons themselves, which shifts multi-icon labels visually.
	-- Compensate only when there is more than one icon.
	local multi_icon = has_icons and icons:find(" ") ~= nil
	local label_y = multi_icon and -1 or 0

	local icon_padding_right
	if has_icons and show_number then
		icon_padding_right = number_icon_gap
	elseif has_icons then
		icon_padding_right = 0
	else
		icon_padding_right = pad
	end

	return {
		drawing = should_draw,
		label = {
			string = has_icons and icons or "",
			color = text_color,
			drawing = has_icons,
			padding_left = 0,
			padding_right = has_icons and pad or 0,
			y_offset = label_y,
		},
		icon = {
			string = show_number and ws_label or "",
			color = text_color,
			drawing = true,
			padding_left = pad,
			padding_right = icon_padding_right,
		},
		background = {
			color = selected and colors.accent or colors.transparent,
		},
	}
end

local function update_all_spaces()
	local now = os.time()
	if update_in_flight_at ~= 0 and (now - update_in_flight_at) < LOCK_TIMEOUT_S then
		update_dirty = true
		return
	end
	update_in_flight_at = now

	sbar.exec(backend.fetch_state_cmd(), function(output)
		update_in_flight_at = 0

		local workspace_icons = {}
		local seen = {}
		local focused = ""
		local parsing_windows = true

		for line in output:gmatch("[^\n]+") do
			if line == "---" then
				parsing_windows = false
			elseif parsing_windows then
				local ws, app = line:match("^(.-)|(.+)$")
				if ws then
					if not workspace_icons[ws] then
						workspace_icons[ws] = ""
						seen[ws] = {}
					end
					local lookup = app_icons[app]
					local icon = ((lookup == nil) and app_icons["default"] or lookup)
					if not seen[ws][icon] then
						if workspace_icons[ws] == "" then
							workspace_icons[ws] = icon
						else
							workspace_icons[ws] = workspace_icons[ws] .. " " .. icon
						end
						seen[ws][icon] = true
					end
				end
			else
				focused = line:gsub("%s+", "")
			end
		end

		local changed = {}
		for ws, space in pairs(space_items) do
			local icons = workspace_icons[ws] or ""
			local selected = ws == focused
			local key = (selected and "1|" or "0|") .. icons
			if space_state[ws] ~= key then
				local was_drawn = space_drawn[ws] or false
				local now_drawn = selected or icons ~= ""
				space_state[ws] = key
				space_drawn[ws] = now_drawn
				changed[#changed + 1] = {
					space = space,
					icons = icons,
					selected = selected,
					label = backend.display_label(ws),
					drawing_flipped = was_drawn ~= now_drawn,
				}
			end
		end

		if #changed > 0 then
			-- Layout changes (drawing, padding, label.string) apply instantly
			-- so the bracket bg never gets caught half-resized when a second
			-- switch arrives mid-animation. The accent ↔ bg2 background color
			-- still animates so the active-state swap reads as smooth.
			-- Skip the color animation when drawing flipped — animating from
			-- the prior color to accent on a workspace that just appeared
			-- causes a visible bg2 flash on the first frame.
			local to_animate = {}
			for _, c in ipairs(changed) do
				local props = build_space_set(c.icons, c.selected, c.label)
				if c.drawing_flipped then
					c.space:set(props)
				else
					local target_color = props.background.color
					props.background = nil
					c.space:set(props)
					to_animate[#to_animate + 1] = { space = c.space, color = target_color }
				end
			end
			if #to_animate > 0 then
				sbar.animate("tanh", 8, function()
					for _, t in ipairs(to_animate) do
						t.space:set({ background = { color = t.color } })
					end
				end)
			end
		end

		if update_dirty then
			update_dirty = false
			update_all_spaces()
		end
	end)
end

-- Creates the per-workspace items once the window manager is reachable.
-- sketchybar can boot before AeroSpace (launchd race), in which case
-- list_workspaces_cmd() returns nothing — the routine below retries every
-- update_freq seconds until it succeeds, so the spaces still appear.
local function ensure_space_items()
	if next(space_items) ~= nil then
		return true
	end
	local workspaces = exec_to_table(backend.list_workspaces_cmd())
	if #workspaces == 0 then
		return false
	end

	-- Vertical divider between the GitHub bell and the space pills. Created
	-- before the space items so the bracket lays it out second (bracket layout
	-- follows item creation order).
	sbar.add("item", "spaces.separator", {
		width = 2,
		icon = { drawing = false },
		label = { drawing = false },
		background = {
			drawing = true,
			height = 16,
			color = colors.white,
		},
		padding_left = 3,
		padding_right = 6,
	})

	for i, workspace in ipairs(workspaces) do
		local space = sbar.add("item", "space." .. workspace:gsub("%s+", "_"), {
			icon = {
				font = { family = settings.font.text, style = settings.font.style_map["Bold"], size = 12 },
				string = "",
				color = colors.white,
				padding_left = 9,
				padding_right = 9,
				y_offset = 0,
				drawing = true,
			},
			label = {
				string = "",
				font = "sketchybar-app-font:Regular:14.0",
				color = colors.base,
				padding_left = 0,
				padding_right = 0,
				y_offset = -1,
				drawing = false,
			},
			background = {
				color = colors.bg2,
				corner_radius = 16,
				height = 19,
			},
			padding_left = 6,
			padding_right = 0,
			drawing = false,
			click_script = backend.click_cmd(workspace),
		})

		space_items[workspace] = space
		space_names[i] = space.name
	end

	-- Invisible spacer that extends the left bracket background past the last
	-- space, adding visual padding on the right end of the spaces pill.
	sbar.add("item", "spaces.right_pad", {
		width = 0,
		icon = { drawing = false },
		label = { drawing = false },
		background = { drawing = false },
	})

	-- Left pill: Apple logo + Aerospace workspaces. Created here (not init.lua)
	-- because bracket members are only resolved at creation time — if the space
	-- items are built on a later routine tick (WM not up at boot), the bracket
	-- must be created together with them to pick them up.
	sbar.add("bracket", "bracket.left", { "github.bell", "spaces.separator", "/space\\..*/", "spaces.right_pad" }, {
		background = {
			color = colors.bg1,
			corner_radius = 16,
			height = 28,
			border_width = 0,
		},
	})
	return true
end

local observer = sbar.add("item", {
	drawing = false,
	updates = true,
	update_freq = 5,
})

-- routine fires every update_freq seconds — backstop against window manager
-- state changes (move-window, window close on inactive workspace, etc.) that
-- don't trigger one of the push events the backend lists. Also re-arms the
-- space items if they couldn't be created at boot (WM not up yet).
local subscribed_events = { "routine" }
for _, ev in ipairs(backend.events) do
	subscribed_events[#subscribed_events + 1] = ev
end
observer:subscribe(subscribed_events, function(env)
	if ensure_space_items() then
		update_all_spaces()
	end
end)

ensure_space_items()
update_all_spaces()

return space_names
