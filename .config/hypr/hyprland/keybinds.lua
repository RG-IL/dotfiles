local vars = require("variables")
local fn   = require("utils.functions")


-- Flags
local locked           = { locked = true }
local mouse            = { mouse = true }
local release          = { release = true }
local repeating        = { repeating = true }
local locked_repeating = { locked = true, repeating = true }
local locked_release   = { locked = true, release = true }

local function normalise_keybind(key)
    return key:gsub("%s+", ""):lower()
end

local function valid_keybind(key)
    return type(key) == "string" and key:match("%S") ~= nil
end

local function repeating_unless_mouse(key)
    return not normalise_keybind(key):find("mouse", 1, true) and repeating or nil
end

local function flatten_keybinds(keybinds, keys)
    keys = keys or {}

    if type(keybinds) == "table" then
        for _, keybind in pairs(keybinds) do
            flatten_keybinds(keybind, keys)
        end
    elseif valid_keybind(keybinds) then
        keys[#keys + 1] = keybinds
    end

    return keys
end

local function create_bind(keybinds, action, flags)
    local get_flags = type(flags) == "function" and flags or function()
        return flags
    end

    for _, key in ipairs(flatten_keybinds(keybinds)) do
        hl.bind(key, action, get_flags(key))
    end
end

local function extend_keybind(base, suffix)
    return valid_keybind(base) and base .. " + " .. suffix or nil
end

-- Launcher
local launcher_default = normalise_keybind("SUPER + SUPER_L")
create_bind(
    vars.kbLauncher,
    hl.dsp.global("caelestia:launcher"),
    function(key)
        return normalise_keybind(key) == launcher_default and release or nil
    end
)
create_bind("SUPER + mouse_up", hl.dsp.global("caelestia:launcherInterrupt"))
create_bind("SUPER + mouse_down", hl.dsp.global("caelestia:launcherInterrupt"))

-- Misc
create_bind(vars.kbSession, hl.dsp.global("caelestia:session"))
create_bind(vars.kbShowSidebar, hl.dsp.global("caelestia:sidebar"))
create_bind(vars.kbClearNotifs, hl.dsp.global("caelestia:clearNotifs"), locked)
create_bind(vars.kbShowPanels, hl.dsp.global("caelestia:showall"))
-- Reset to the first layout (English) before locking, so the password prompt
-- always starts in a layout the password can actually be typed in.
create_bind(vars.kbLock, function()
    hl.dispatch(hl.dsp.exec_cmd("hyprctl switchxkblayout all 0"))
    hl.dispatch(hl.dsp.global("caelestia:lock"))
end)

-- Keyboard layout (tap Ctrl, same trick as the Super-tap launcher)
-- `locked` keeps this bind alive on the lock screen (the lock grabs the
-- keyboard and Hyprland drops all non-locked binds), so you can still switch
-- layouts while locked instead of getting stuck in Hebrew.
create_bind(vars.kbSwitchLayout, hl.dsp.exec_cmd("hyprctl switchxkblayout all next"), locked_release)

-- Restore lock
create_bind(vars.kbRestoreLock, function()
    hl.dispatch(hl.dsp.exec_cmd("caelestia shell -d"))
    hl.dispatch(hl.dsp.global("caelestia:lock"))
end, locked)

-- Kill/restart
create_bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("caelestia shell -k"), release)
create_bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("caelestia shell -r -d"), release)

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    create_bind(extend_keybind(vars.kbGoToWs, key), fn.wsaction("focus", "", i))
    create_bind(extend_keybind(vars.kbMoveWinToWs, key), fn.wsaction("move", "", i))
    create_bind(extend_keybind(vars.kbMoveWinToWsSilent, key), fn.wsaction("move_silent", "", i))
    create_bind(extend_keybind(vars.kbGoToWsGroup, key), fn.wsaction("focus", "group", i))
    create_bind(extend_keybind(vars.kbMoveWinToWsGroup, key), fn.wsaction("move", "group", i))
end

-- Go to workspace -1/+1
create_bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), repeating_unless_mouse)
create_bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), repeating_unless_mouse)

-- Go to workspace group -1/+1
create_bind(vars.kbPrevWsGroup, hl.dsp.focus({ workspace = "-10" }), repeating_unless_mouse)
create_bind(vars.kbNextWsGroup, hl.dsp.focus({ workspace = "+10" }), repeating_unless_mouse)

-- Move window to workspace -1/+1
create_bind(vars.kbMoveWinToWsNext, hl.dsp.window.move({ workspace = "+1" }), repeating_unless_mouse)
create_bind(vars.kbMoveWinToWsPrev, hl.dsp.window.move({ workspace = "-1" }), repeating_unless_mouse)

-- Move window to/from special workspace
create_bind(vars.kbMoveWinToWsSpecial, hl.dsp.window.move({ workspace = "special:special" }))
create_bind(vars.kbMoveWinToWsSilentSpecial, hl.dsp.window.move({ workspace = "special:special", follow = false }))
create_bind(vars.kbMoveWinFromWsSpecial, hl.dsp.window.move({ workspace = "e+0" }))

-- Window groups
create_bind(vars.kbWindowCycleNext, hl.dsp.window.cycle_next(), repeating)
create_bind(vars.kbWindowCyclePrev, hl.dsp.window.cycle_next({ next = false }), repeating)
create_bind(vars.kbWindowGroupCycleNext, hl.dsp.group.next(), repeating)
create_bind(vars.kbWindowGroupCyclePrev, hl.dsp.group.prev(), repeating)
create_bind(vars.kbToggleGroup, hl.dsp.group.toggle())
create_bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }))
create_bind(vars.kbGroupLockActive, hl.dsp.group.lock())

-- Window actions
for _, dir in ipairs({ "left", "right", "up", "down" }) do
    create_bind("SUPER + " .. dir, hl.dsp.focus({ direction = dir }))
    create_bind("SUPER + SHIFT + " .. dir, hl.dsp.window.move({ direction = dir }))
end

create_bind(vars.kbWindowDecreaseWidth, fn.resize_active_window(-10, 0), repeating)
create_bind(vars.kbWindowIncreaseWidth, fn.resize_active_window(10, 0), repeating)
create_bind(vars.kbWindowDecreaseHeight, fn.resize_active_window(0, -10), repeating)
create_bind(vars.kbWindowIncreaseHeight, fn.resize_active_window(0, 10), repeating)

create_bind({ vars.kbMoveWindow, "SUPER + mouse:272" }, hl.dsp.window.drag(), mouse)
create_bind({ vars.kbResizeWindow, "SUPER + mouse:273" }, hl.dsp.window.resize(), mouse)
create_bind(vars.kbCenterWindow, hl.dsp.window.center())
create_bind(vars.kbNormalizeWindow, function()
    hl.dispatch(hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
    hl.dispatch(hl.dsp.window.center())
end)
create_bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end)
create_bind(vars.kbPinWindow, hl.dsp.window.pin())
create_bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
create_bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
-- Fake fullscreen (same as Omarchy's "tiled full screen"): the app is told it's
-- fullscreen, but the window keeps its size and the layout doesn't move.
create_bind(vars.kbWindowFakeFullscreen, function()
    local a = hl.get_active_window()
    if a then
        if a.fullscreen_client == 2 then
            hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 0 }))
        else
            hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = 2 }))
        end
    end
end)
create_bind(vars.kbToggleWindowFloating, hl.dsp.window.float())
create_bind(vars.kbCloseWindow, hl.dsp.window.close())

-- Special workspace toggles
create_bind(vars.kbSpecialWs, fn.toggle("specialws"))
create_bind(vars.kbSystemMonitorWs, fn.toggle("sysmon"))
create_bind(vars.kbMusicWs, fn.toggle("music"))
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
create_bind(vars.kbTodoWs, fn.toggle("todo"))

-- Wispr Flow status pill
-- The pill normally lives in special:wispr (see rules.lua) so it never shows
-- up. While Ctrl+Alt is held (the dictation hold), pull it onto the active
-- workspace so it is visible; releasing either key parks it again. A quick
-- double-press pins it to its workspace until the next Ctrl+Alt press.
local wispr_pin        = false
local wispr_last_show  = 0
local wispr_double_gap = 0.35 -- max seconds between the presses of a double-press

local wispr_pill_title = { Status = true, ["Flow Status Indicator"] = true }

local function wispr_pill()
    for _, win in ipairs(hl.get_windows() or {}) do
        if win.class == "wispr-flow" and wispr_pill_title[win.title] then
            return win
        end
    end
end

-- Wall clock with sub-second precision (os.time is whole seconds and os.clock
-- is CPU time). Reading /proc/uptime is a tiny kernel file, non-blocking.
local function wispr_now()
    local f = io.open("/proc/uptime", "r")
    if not f then return 0 end
    local t = tonumber(f:read("*l"):match("^%s*([%d.]+)"))
    f:close()
    return t or 0
end

local function show_wispr_pill()
    local pill = wispr_pill()
    if not pill then return end

    local now = wispr_now()
    if wispr_pin then
        wispr_pin = false -- any press unpins a pinned pill
    elseif now - wispr_last_show < wispr_double_gap then
        wispr_pin = true -- second press of a double-press pins it
    end
    wispr_last_show = now

    local ws = hl.get_active_workspace()
    if not ws then return end

    -- Named and special workspaces have no positive id, use their name instead
    local target = (type(ws.id) == "number" and ws.id > 0) and ws.id or ws.name
    hl.dispatch(hl.dsp.window.move({ window = pill, workspace = target, follow = false }))

    -- Park it at the very bottom middle of the monitor (the floating "center"
    -- rule would otherwise yank it to mid-screen every time it is shown)
    local screen = hl.get_active_monitor()
    if screen and screen.width and screen.height and pill.size then
        local width  = screen.width / (screen.scale or 1)
        local height = screen.height / (screen.scale or 1)
        local x      = math.floor(screen.x + (width - pill.size.x) / 2)
        local y      = math.floor(screen.y + height - pill.size.y - 10)
        hl.dispatch(hl.dsp.window.move({ x = x, y = y, relative = false, window = pill }))
    end
end

local function park_wispr_pill()
    local pill = wispr_pill()
    if not pill then return end

    -- Pinned pills stay put until the next Ctrl+Alt press unpins them
    if wispr_pin then return end

    -- No-op unless the pill is currently out of its home workspace, so plain
    -- ctrl/alt shortcuts (which fire these release binds too) don't touch it
    local name = pill.workspace and pill.workspace.name
    if not name or name == "special:wispr" then return end

    hl.dispatch(hl.dsp.window.move({ window = pill, workspace = "special:wispr", follow = false }))
end

-- Keysym binds treat keys as plain keys, so the order they are pressed in
-- matters: bind both orders so it fires no matter which key is held first.
create_bind({ "CTRL + Alt_L", "CTRL + Alt_R" }, show_wispr_pill) -- Ctrl held, Alt pressed second
create_bind({ "ALT + Ctrl_L", "ALT + Ctrl_R" }, show_wispr_pill) -- Alt held, Ctrl pressed second
-- Releasing either key while the other is still held parks the pill. Bare
-- keysym release binds don't work here (the key's own modifier is required in
-- the modmask and is already gone at release time), so these are chords too.
create_bind({ "CTRL + Alt_L", "CTRL + Alt_R" }, park_wispr_pill, release)
create_bind({ "ALT + Ctrl_L", "ALT + Ctrl_R" }, park_wispr_pill, release)

-- Apps
create_bind(vars.kbTerminal, hl.dsp.exec_cmd(vars.terminal))
create_bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser))
create_bind(vars.kbEditor, hl.dsp.exec_cmd(vars.editor))
create_bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer))
create_bind(vars.kbAudioSettings, hl.dsp.exec_cmd(vars.audioSettings))

-- Utilities
create_bind(vars.kbScreenshot, hl.dsp.exec_cmd("caelestia screenshot"), locked)
create_bind(vars.kbScreenshotFreeze, hl.dsp.global("caelestia:screenshotFreeze"))
create_bind(vars.kbScreenshotRegion, hl.dsp.global("caelestia:screenshot"))
create_bind(vars.kbRecord, hl.dsp.exec_cmd("caelestia record"))
create_bind(vars.kbRecordSound, hl.dsp.exec_cmd("caelestia record -s"))
create_bind(vars.kbRecordRegion, hl.dsp.exec_cmd("caelestia record -r"))
create_bind(vars.kbColorPicker, hl.dsp.exec_cmd("hyprpicker -a"))

-- Brightness
create_bind("XF86MonBrightnessUp", hl.dsp.global("caelestia:brightnessUp"), locked)
create_bind("XF86MonBrightnessDown", hl.dsp.global("caelestia:brightnessDown"), locked)

-- Media
create_bind({ vars.kbMediaToggle, "XF86AudioPlay", "XF86AudioPause" }, hl.dsp.global("caelestia:mediaToggle"), locked)
create_bind({ vars.kbMediaNext, "XF86AudioNext" }, hl.dsp.global("caelestia:mediaNext"), locked)
create_bind({ vars.kbMediaPrev, "XF86AudioPrev" }, hl.dsp.global("caelestia:mediaPrev"), locked)
create_bind({ vars.kbMediaStop, "XF86AudioStop" }, hl.dsp.global("caelestia:mediaStop"), locked)

-- Volume
create_bind({ vars.kbVolumeMute, "XF86AudioMute" }, hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), locked)
create_bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), locked)
create_bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    locked_repeating
)
create_bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    locked_repeating
)

-- Sleep
create_bind(vars.kbSleep, hl.dsp.exec_cmd(vars.sleepGestureCmd), locked)

-- Clipboard and emoji picker
create_bind(vars.kbClipboard, hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard"))
create_bind(vars.kbClipboardDel, hl.dsp.exec_cmd("pkill fuzzel || caelestia clipboard -d"))
create_bind(vars.kbEmoji, hl.dsp.exec_cmd("pkill fuzzel || caelestia emoji -p"))
create_bind(
    vars.kbClipboardPasteLatest,
    hl.dsp.exec_cmd('sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"'),
    locked
)
