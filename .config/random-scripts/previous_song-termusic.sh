#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Previous_song-termusic
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author RaphaelGrumbach
# @raycast.authorURL https://raycast.com/RaphaelG

tmux list-panes -t music -F "#{session_name}:#{window_index}.#{pane_index} #{pane_current_command}" |
while read pane cmd; do
    if [[ "$cmd" == *termusic* ]]; then
        tmux send-keys -t "$pane" "N"
        exit 0
    fi
done

exit 0


