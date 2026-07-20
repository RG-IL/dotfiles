#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/ghostty/config"
LOCK="/tmp/ghostty-blur-increase.lock"
STEP=5

touch "$LOCK"

while [[ -f "$LOCK" ]]; do
  current=$(sed -n 's/^background-blur-radius = //p' "$CONFIG" || echo 0)
  new=$((current + STEP))
  if grep -q '^background-blur-radius' "$CONFIG" 2>/dev/null; then
    sed -i '' "s/^background-blur-radius = .*/background-blur-radius = $new/" "$CONFIG"
  else
    echo "background-blur-radius = $new" >> "$CONFIG"
  fi
  pgrep -q ghostty && osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' 2>/dev/null || true
  sleep 0.05
done
