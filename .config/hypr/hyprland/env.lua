local vars = require("variables")

-- Themes
hl.env("QT_QPA_PLATFORMTHEME", "qtengine")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("XCURSOR_THEME", vars.cursorTheme)
hl.env("XCURSOR_SIZE", vars.cursorSize)
hl.env("HYPRCURSOR_THEME", vars.cursorTheme)
hl.env("HYPRCURSOR_SIZE", vars.cursorSize)

-- Toolkit backends
hl.env("GDK_BACKEND", "wayland,x11")
-- Without this, ghostty/GTK drives blur through ext-background-effect-v1 and
-- every ghostty window ends up unblurred on this compositor. With it,
-- Hyprland's own blur config applies. The var must also reach systemd/dbus
-- activated instances (the +new-window path), so execs.lua imports it there.
hl.env("GDK_WAYLAND_DISABLE", "ext_background_effect_manager_v1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland,x11,windows")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- XDG specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Others
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
