-- Universal copy/paste, works in terminals and GUI apps alike
hl.bind("SUPER + C", hl.dsp.send_shortcut({ mods = "CTRL", key = "Insert" }), { description = "Universal copy" })
hl.unbind("SUPER + V")
hl.bind("SUPER + V", hl.dsp.send_shortcut({ mods = "SHIFT", key = "Insert" }), { description = "Universal paste" })
hl.unbind("SUPER + D")
hl.bind("SUPER + D", hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard"), { description = "opens dashboard" })
