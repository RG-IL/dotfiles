#!/bin/bash

# sketchybar starts with SIGCHLD set to SIG_IGN, and POSIX shells force that
# disposition onto every child they spawn. Homebrew's portable Ruby then can't
# capture child statuses (Process.detach returns nil) and `brew` crashes with
# "undefined method 'exitstatus' for nil". A python helper resets SIGCHLD in the
# process that directly spawns brew, sidestepping the shell entirely.
source "$CONFIG_DIR/colors.sh"

COUNT="$(/usr/bin/python3 -c '
import signal, subprocess

signal.signal(signal.SIGCHLD, signal.SIG_DFL)
r = subprocess.run(
    ["/opt/homebrew/bin/brew", "outdated", "--quiet"],
    capture_output=True,
    text=True,
)
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
