#!/usr/bin/env bash
# Event-driven now-playing watcher for the sketchybar media widget.
#
# macOS 15.4+ killed the MediaRemote entitlement that sketchybar's native
# `media_change` event relied on, so the widget falls back to a poll. This
# script restores true event-driven updates: `media-control stream` registers
# for Now Playing change notifications through a platform binary (perl) and
# idles at ~0% CPU, emitting a JSON line only when media state changes.
#
# The stream payload is the authoritative state: it fires ~60ms after a
# play/pause/track change, whereas re-querying the media daemon (media_info.sh)
# returns STALE state for ~1s after a pause. So this watcher merges each line
# into /tmp/status/media as <playing:0|1>|<title>|<artist> and fires the custom
# media_update event; the widget renders directly from that file instead of
# re-probing. Elapsed-time and other cosmetic diffs are ignored.
#
# Single-instance guard (pidfile) so a sketchybar reload can't spawn a second
# watcher. The stream is restarted if it exits.

STATUS_DIR="/tmp/status"
PIDFILE="$STATUS_DIR/media_watch.pid"
STATE_FILE="$STATUS_DIR/media"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
	exit 0
fi

mkdir -p "$STATUS_DIR"
echo "$$" > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

playing=0
title=""
artist=""
last_key=""

# The stream runs in a subshell, so on a restart its state resets; re-seed it
# from the last written state so a restart never spuriously re-emits.
if [[ -f "$STATE_FILE" ]]; then
	IFS='|' read -r playing title artist < "$STATE_FILE"
	last_key="$playing|$title|$artist"
fi

emit() {
	local key="$playing|$title|$artist"
	if [[ "$key" == "$last_key" ]]; then
		return
	fi
	last_key="$key"
	printf '%s|%s|%s\n' "$playing" "$title" "$artist" > "$STATE_FILE"
	sketchybar --trigger media_update
}

while true; do
	media-control stream 2>/dev/null | while IFS= read -r line; do
		[[ -n "$line" ]] || continue

		# Cheap pre-filter: only lines touching play/title/artist matter.
		case "$line" in
			*'"playing"'* | *'"title"'* | *'"artist"'*) ;;
			*) continue ;;
		esac

		if echo "$line" | jq -e '.payload | has("playing")' >/dev/null 2>&1; then
			playing=$(echo "$line" | jq -r 'if .payload.playing then 1 else 0 end')
		fi
		if echo "$line" | jq -e '.payload | has("title")' >/dev/null 2>&1; then
			title=$(echo "$line" | jq -r '.payload.title // empty')
		fi
		if echo "$line" | jq -e '.payload | has("artist")' >/dev/null 2>&1; then
			artist=$(echo "$line" | jq -r '.payload.artist // empty')
		fi
		[[ "$title" == "null" ]] && title=""
		[[ "$artist" == "null" ]] && artist=""
		emit
	done
	sleep 1
done
