#!/usr/bin/env bash
# Runs `brew upgrade --formula` under the launchd status daemon's responsibility
# chain, refreshes the package state files, and clears the running flag. Spawned
# detached by status_daemon.sh when the user clicks the sketchybar packages
# widget. brew runs under launchd, never under sketchybar.
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
STATUS_DIR="/tmp/status"
LOG="$STATUS_DIR/packages_upgrade.log"

/usr/bin/python3 -c '
import os, signal, subprocess
signal.signal(signal.SIGCHLD, signal.SIG_DFL)
env = dict(os.environ)
subprocess.run(
    ["/opt/homebrew/bin/brew", "upgrade", "--formula"],
    env=env,
)
' > "$LOG" 2>&1

# Refresh state files (detached-safe split in refresh_packages.sh).
"$SCRIPTS/refresh_packages.sh"

rm -f "$STATUS_DIR/upgrade_running"
sketchybar -m --trigger brew_upgrade 2>/dev/null
