#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title termusic-popup
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author RaphaelGrumbach
# @raycast.authorURL https://raycast.com/RaphaelG

window_width=150
window_height=40
window_x=80
window_y=100
if ! pgrep -x termusic-server >/dev/null; then
    termusic-server >/dev/null 2>&1 &
fi
exec env -i \
    HOME="$HOME" \
    PATH="/opt/homebrew/bin:/usr/bin:/bin" \
    open -na Ghostty.app --args \
    --maximize=false \
    --window-width="$window_width" \
    --window-height="$window_height" \
    --window-position-x="$window_x" \
    --window-position-y="$window_y" \
    -e env sh -c '
  termusic --layout-4 && exit
' || true
