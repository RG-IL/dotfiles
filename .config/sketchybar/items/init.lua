local colors = require("colors")

-- ──────────────────────────── LEFT ────────────────────────────
require("items.widgets.caffeinate")

-- ──────────────── CENTER — LEFT of notch ──────────────────────

-- Fired by the bluetooth widget when its label width changes, so the media
-- title can re-measure how much space remains before the notch.
sbar.add("event", "media_space_changed")

require("items.media")

-- Invisible spacer that covers the MacBook Pro notch.
-- Adjust 'width' to match the actual cutout: too wide leaves visible pill
-- space between the notch and the bluetooth/clock; too narrow and items bleed
-- under the cutout. On this display (2560x1664 scaled → 1470pt) the cutout is
-- ~150–175pt.
sbar.add("item", "center.notch", {
	position = "center",
	width = 180,
	icon = { drawing = false },
	label = { drawing = false },
	background = { color = colors.transparent },
})

-- ──────────────── CENTER — RIGHT of notch ─────────────────────
require("items.widgets.bluetooth")
require("items.calendar")

-- Transparent spacer that extends the notch pill past the clock.
sbar.add("item", "center.media.pad_right", {
	position = "center",
	width = 2,
	icon = { drawing = false },
	label = { drawing = false },
	background = { color = colors.transparent },
})

-- ─────────────────────────── RIGHT ────────────────────────────
require("items.widgets.battery")
require("items.widgets.volume")
require("items.widgets.packages")
require("items.widgets.wifi")

-- ══════════════════════════════════════════════════════════════
-- BRACKETS — drawn after all items are created
-- ══════════════════════════════════════════════════════════════

CORNER_RADIUS = 16

-- Left pill: caffeinate toggle
sbar.add("bracket", "bracket.left", {
	"widgets.caffeinate",
}, {
	background = {
		color = colors.bg1,
		corner_radius = CORNER_RADIUS,
		height = 28,
		border_width = 0,
	},
})

-- Center notch pill: media — [notch] — bluetooth + clock
-- The pill background spans both halves; the notch hardware creates the visual gap.
-- The yellow clock pill (bracket.clock) draws on top of center.time.
sbar.add("bracket", "bracket.media", {
	"/^center\\.media.*/",
	"center.notch",
	"center.time",
	"center.date",
	"widgets.bluetooth",
	"center.media.pad_right",
}, {
	background = {
		color = colors.bg3,
		corner_radius = 4,
		height = 24,
		border_width = 0,
	},
})

-- Yellow pill around the time only, nested inside the notch pill.
sbar.add("bracket", "bracket.clock", {
	"center.time",
}, {
	background = {
		color = colors.accent,
		corner_radius = 3,
		height = 18,
		border_width = 0,
	},
})

-- Right pill: Packages + Volume + Battery + Wi-Fi
sbar.add("bracket", "bracket.right", {
	"widgets.wifi",
	"widgets.packages",
	"widgets.volume.icon",
	"widgets.volume",
	"widgets.battery",
}, {
	background = {
		color = colors.bg1,
		corner_radius = CORNER_RADIUS,
		height = 28,
		border_width = 0,
	},
})
