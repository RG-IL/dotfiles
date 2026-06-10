on run
    tell application "Finder"
        set sel to selection
        if sel is {} then return
        set paths to "--focus=Finder "
        repeat with f in sel
            set paths to paths & quoted form of (POSIX path of (f as alias)) & " "
        end repeat
        do shell script "~/.config/yazi/blip-send.py " & paths
    end tell
end run
