#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title kill
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 💀
# @raycast.hotkey alt+cmd+q

# Documentation:
# @raycast.description kill tmux server and quit ghostty
# @raycast.author RaphaelGrumbach

# i dont want to see any output
# i still see A Error: Process terminated with status 1 and i dont want to see it its because of termusic
tmux kill-server 2>/dev/null
osascript -e 'tell application "Ghostty" to quit'
