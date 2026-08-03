local colors = require("colors")

-- ──────────────────────────── LEFT ────────────────────────────
require("items.github")
require("items.spaces")

-- ──────────────── CENTER — LEFT of notch ──────────────────────
require("items.media")

-- Invisible spacer that covers the MacBook Pro notch.
-- Adjust 'width' if items bleed under the notch:
--   14" MBP default res  → try 200–220
--   16" MBP default res  → try 220–250
sbar.add("item", "center.notch", {
	position = "center",
	width = 275,
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

-- ══════════════════════════════════════════════════════════════
-- BRACKETS — drawn after all items are created
-- ══════════════════════════════════════════════════════════════

CORNER_RADIUS = 16

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

-- Right pill: Packages + Volume + Battery
sbar.add("bracket", "bracket.right", {
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
