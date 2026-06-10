#!/usr/bin/osascript

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Send to blip
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 

# @Documentation:
# @raycast.author RaphaelGrumbach
# @raycast.authorURL https://github.com/RaphaelGrumbach
# @raycast.description Send selected files in Finder to Blip

tell application "Finder"
	set sel to selection
	if sel is {} then return
	set paths to "--focus=Finder "
	repeat with f in sel
		set paths to paths & quoted form of (POSIX path of (f as alias)) & " "
	end repeat
	try
		do shell script "/Library/Frameworks/Python.framework/Versions/3.14/bin/python3 /Users/raphael/.config/yazi/blip-send.py " & paths
	on error errMsg
		do shell script "echo " & quoted form of errMsg & " > /tmp/blip-error.txt"
	end try
end tell
