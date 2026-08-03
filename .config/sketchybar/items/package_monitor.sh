#!/bin/bash

# Counts the raw brew-outdated tally written by the launchd status daemon
# (/tmp/status/packages, from packages_info.sh) and color-codes the item.
# The daemon runs brew under launchd, so sketchybar never spawns brew.
source "$CONFIG_DIR/colors.sh"

COUNT="$(cat /tmp/status/packages 2>/dev/null)"
COUNT="${COUNT:-0}"

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
