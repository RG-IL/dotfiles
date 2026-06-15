#!/usr/bin/env bash
set -euo pipefail

MAIN="$HOME/.config/ghostty/config"
CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
STEP=0.05

current=$(sed -n 's/^background-opacity = //p' "$CONFIG" || sed -n 's/^background-opacity = //p' "$MAIN" || echo 1)
new=$(awk "BEGIN { v = $current - $STEP; if (v < 0) v = 0; printf \"%.2f\", v }")
if grep -q '^background-opacity' "$CONFIG" 2>/dev/null; then
  sed -i '' "s/^background-opacity = .*/background-opacity = $new/" "$CONFIG"
else
  echo "background-opacity = $new" >> "$CONFIG"
fi

pgrep -q ghostty && osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' 2>/dev/null || true
