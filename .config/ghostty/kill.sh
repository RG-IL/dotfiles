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

tmux kill-server 2>/dev/null
osascript -e 'tell application "Ghostty" to quit'
