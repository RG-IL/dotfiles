#!/usr/bin/env bash
# Event-driven aerospace state watcher for the sketchybar spaces widget.
#
# Replaces the exec-on-workspace-change callback in aerospace.toml as the single
# push source: `aerospace subscribe` keeps a socket open at ~0% CPU and emits one
# JSON line per window-manager event. Every event means the space pills (and the
# media title budget, which depends on the left bracket width) may have changed,
# so we fire the custom aerospace_workspace_change event and let the widgets
# re-fetch state.
#
# Subscribed events: focus-changed (focus moves between windows, incl. the
# close-with-focus-move case), focused-workspace-changed (workspace switch),
# focused-monitor-changed (multi-monitor focus), window-detected (new window).
# binding-triggered (every key press) and mode-changed are deliberately excluded.
#
# No state merge is needed — spaces.lua re-runs `aerospace list-windows` on each
# trigger. The widget's slow routine poll stays as the backstop for window moves
# to inactive workspaces, which emit no event.
#
# Single-instance guard (pidfile) so a sketchybar reload can't spawn a second
# watcher. The stream is restarted if it exits.

PIDFILE="/tmp/status/aerospace_watch.pid"

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE" 2>/dev/null)" 2>/dev/null; then
	exit 0
fi

mkdir -p /tmp/status
echo "$$" > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

while true; do
	aerospace subscribe focus-changed focused-workspace-changed focused-monitor-changed window-detected 2>/dev/null | while IFS= read -r line; do
		[[ -n "$line" ]] || continue
		sketchybar --trigger aerospace_workspace_change
	done
	sleep 1
done
