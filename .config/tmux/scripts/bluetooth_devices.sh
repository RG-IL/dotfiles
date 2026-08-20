#!/usr/bin/env bash
# Bluetooth device state for the sketchybar bluetooth widget (and tmux).
# Emits one line per unique paired device: addr|name|connected|battery,
# preceded by the adapter power state and a '---' separator.
# Runs from the launchd status daemon so the periodic blueutil calls are not
# attributed to sketchybar (avoids tccd re-validation of its BluetoothAlways grant).
# The connected flag is taken from `blueutil --paired` (the same source that
# lists addresses): `--info` occasionally disagrees with macOS and reports a
# connected device as "not connected", which stranded devices in the widget.
blueutil -p 2>/dev/null
echo '---'
accps=$(pmset -g accps 2>/dev/null)
seen=""
blueutil --paired 2>/dev/null | grep -E '^address:' | while IFS= read -r line; do
	addr=$(printf '%s' "$line" | sed -n 's/.*address: \([0-9a-fA-F-]*\),.*/\1/p')
	[ -z "$addr" ] && continue
	case "$seen" in *"|$addr|"*) continue ;; esac
	seen="$seen|$addr|"
	if printf '%s' "$line" | grep -q ', connected'; then conn='1'; else conn='0'; fi
	name=$(printf '%s' "$line" | sed -n 's/.*name: "\([^"]*\)".*/\1/p' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
	[ -z "$name" ] && continue
	info=$(blueutil --info "$addr" 2>/dev/null)
	bat=$(printf '%s' "$accps" | grep -F "$name" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
	[ -n "$bat" ] || bat=$(printf '%s' "$info" | grep -i battery | grep -oE '[0-9]+' | head -1)
	echo "$addr|$name|$conn|${bat:-}"
done
