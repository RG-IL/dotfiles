#!/usr/bin/env bash
# Runs packages_info.sh (brew outdated) and splits its output into
# /tmp/status/packages (count line 1) and /tmp/status/packages_list
# (remaining name|installed|latest lines). Spawned detached by
# status_daemon.sh on the 600-cycle cadence so a slow brew auto-update
# cannot freeze the daemon loop; also called by upgrade_packages.sh after
# `brew upgrade`. brew runs under launchd, never under sketchybar.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
STATUS_DIR="/tmp/status"

if "$SCRIPTS/packages_info.sh" > "$STATUS_DIR/packages.tmp" 2>/dev/null; then
  head -n 1 "$STATUS_DIR/packages.tmp" > "$STATUS_DIR/packages"
  tail -n +2 "$STATUS_DIR/packages.tmp" > "$STATUS_DIR/packages_list"
fi
rm -f "$STATUS_DIR/packages.tmp"
rm -f "$STATUS_DIR/packages_refresh_running"
