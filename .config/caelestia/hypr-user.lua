-- Universal copy/paste, works in terminals and GUI apps alike
hl.bind("SUPER + C", hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert" }), { description = "Universal copy" })
hl.unbind("SUPER + V")
hl.bind("SUPER + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), { description = "Universal paste" })
hl.unbind("SUPER + D")
hl.bind("SUPER + D", hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"), { description = "opens dashboard" })

-- Spotify on native Wayland reports a lowercase class, so route it to the music
-- workspace here (the dots' rule only matches the X11 "Spotify" class)
hl.window_rule({ match = { class = "spotify" }, workspace = "special:music" })

-- XWayland apps (Steam etc): render at native 1440p instead of being
-- stretched by the 1.07 desktop scale, keeps them pixel-crisp
hl.config({ xwayland = { force_zero_scaling = true } })
