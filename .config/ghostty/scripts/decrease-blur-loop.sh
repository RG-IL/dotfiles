#!/usr/bin/env bash
set -euo pipefail

CONFIG="$HOME/.config/ghostty/config"
LOCK="/tmp/ghostty-blur-decrease.lock"
STEP=5

touch "$LOCK"

while [[ -f "$LOCK" ]]; do
  current=$(sed -n 's/^background-blur-radius = //p' "$CONFIG" || echo 0)
  new=$((current - STEP))
  [[ $new -lt 0 ]] && new=0
  sed -i '' "s/^background-blur-radius = .*/background-blur-radius = $new/" "$CONFIG"
  pgrep -q ghostty && osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "Reload Configuration" of menu "Ghostty" of menu bar 1' 2>/dev/null || true
  sleep 0.05
done
