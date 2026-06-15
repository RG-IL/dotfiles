#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/ghostty/config"
LOCK="/tmp/ghostty-opacity-decrease.lock"
STEP=0.05

touch "$LOCK"

while [[ -f "$LOCK" ]]; do
  current=$(sed -n 's/^background-opacity = //p' "$CONFIG" || echo 1)
  new=$(awk "BEGIN { v = $current - $STEP; if (v < 0) v = 0; printf \"%.2f\", v }")
  sed -i '' "s/^background-opacity = .*/background-opacity = $new/" "$CONFIG"
  pgrep -q ghostty && osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' 2>/dev/null || true
  sleep 0.05
done
