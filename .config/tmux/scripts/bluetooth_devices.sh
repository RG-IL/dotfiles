#!/usr/bin/env bash
# Bluetooth device state for the sketchybar bluetooth widget (and tmux).
# Emits one line per unique paired device: addr|name|connected|battery,
# preceded by the adapter power state and a '---' separator.
# Runs from the launchd status daemon so the periodic blueutil calls are not
# attributed to sketchybar (avoids tccd re-validation of its BluetoothAlways grant).
blueutil -p 2>/dev/null
echo '---'
accps=$(pmset -g accps 2>/dev/null)
blueutil --paired 2>/dev/null | grep -oE 'address: [0-9a-fA-F-]+' | awk '{print $2}' | sort -u | while read -r addr; do
	info=$(blueutil --info "$addr" 2>/dev/null)
	name=$(printf '%s' "$info" | sed -n 's/.*name: "\([^"]*\)".*/\1/p')
	[ -z "$name" ] && continue
	if printf '%s' "$info" | grep -q ', connected'; then conn='1'; else conn='0'; fi
	bat=$(printf '%s' "$accps" | grep -F "$name" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
	[ -n "$bat" ] || bat=$(printf '%s' "$info" | grep -i battery | grep -oE '[0-9]+' | head -1)
	echo "$addr|$name|$conn|${bat:-}"
done
