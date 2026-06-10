on run argv
    if (count of argv) is 0 then return
    set cmd to "~/.config/yazi/blip-send.py"
    repeat with f in argv
        set cmd to cmd & " " & quoted form of (POSIX path of f)
    end repeat
    do shell script cmd
end run
