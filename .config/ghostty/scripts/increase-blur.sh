#!/usr/bin/env bash
set -euo pipefail

MAIN="$HOME/.config/ghostty/config"
CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
STEP=5

current=$(sed -n 's/^background-blur-radius = //p' "$CONFIG" || sed -n 's/^background-blur-radius = //p' "$MAIN" || echo 0)
new=$((current + STEP))

if grep -q '^background-blur-radius' "$CONFIG" 2>/dev/null; then
  sed -i '' "s/^background-blur-radius = .*/background-blur-radius = $new/" "$CONFIG"
else
  echo "background-blur-radius = $new" >> "$CONFIG"
fi

pgrep -q ghostty && osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' 2>/dev/null || true
