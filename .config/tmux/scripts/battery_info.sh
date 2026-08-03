#!/usr/bin/env bash
# Raw battery state for the shared status files, consumed by tmux (tmux-battery
# plugin scripts) and sketchybar (battery.lua). Emits: charging|pct|status where
# status is the pmset token (discharging|charging|charged|...) used by the tmux
# battery icon logic. One pmset read total for both bars.
batt="$(pmset -g batt 2>/dev/null)"
pct="$(printf '%s' "$batt" | grep -oE '[0-9]+%' | head -1 | tr -d '%')"
status="$(printf '%s' "$batt" | awk -F '; *' 'NR==2 { print $2 }')"
case "$status" in
charging | charged) charging=1 ;;
*) charging=0 ;;
esac
echo "${charging}|${pct:-0}|${status:-}"
