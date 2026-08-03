#!/bin/bash

# sketchybar starts with SIGCHLD set to SIG_IGN, and POSIX shells force that
# disposition onto every child they spawn. Homebrew's portable Ruby then can't
# capture child statuses (Process.detach returns nil) and `brew` crashes with
# "undefined method 'exitstatus' for nil". A python helper resets SIGCHLD in the
# process that directly spawns brew, sidestepping the shell entirely.
source "$CONFIG_DIR/colors.sh"

# --formula: default `brew outdated` also evaluates auto-updating casks
# (input-source-pro, zen, …) via their app bundle version, so a cask that has a
# newer version available but hasn't self-updated yet shows as a phantom "1"
# that `brew upgrade` can never clear. Formula-only matches what brew upgrade
# can actually update. HOMEBREW_NO_AUTO_UPDATE keeps the check fast and
# deterministic (no mid-update tap state). A failed brew run reports 0 rather
# than a bogus partial count.
COUNT="$(/usr/bin/python3 -c '
import os, signal, subprocess

signal.signal(signal.SIGCHLD, signal.SIG_DFL)
env = dict(os.environ)
env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
r = subprocess.run(
    ["/opt/homebrew/bin/brew", "outdated", "--formula", "--quiet"],
    capture_output=True,
    text=True,
    env=env,
)
if r.returncode != 0:
    print(0)
else:
    print(len([line for line in r.stdout.splitlines() if line.strip()]))
')"

COLOR=$RED
LABEL_PAD_R=8

case "$COUNT" in
[3-5][0-9])
    COLOR=$ORANGE
    ;;
[1-2][0-9])
    COLOR=$YELLOW
    ;;
[1-9])
    COLOR=$WHITE
    ;;
0)
    COLOR=$GREEN
    COUNT=""
    LABEL_PAD_R=0
    ;;
esac

sketchybar --set $NAME label=$COUNT icon.color=$COLOR label.padding_right=$LABEL_PAD_R
