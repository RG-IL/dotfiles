#!/bin/bash
# Counts the raw brew-outdated tally written by the launchd status daemon
# (/tmp/status/packages, from packages_info.sh) and color-codes the item.
# While the daemon runs `brew upgrade` (flag file present) it shows the update
# icon in the accent color with no count. The daemon runs brew under launchd,
# so sketchybar never spawns brew.
source "$CONFIG_DIR/colors.sh"

COUNT="$(cat /tmp/status/packages 2>/dev/null)"
COUNT="${COUNT:-0}"

ICON="󰏗"
COLOR=$GREEN
LABEL_PAD_R=8

if [[ -f /tmp/status/upgrade_running ]]; then
    ICON="󰁡"
    COLOR=$GREY
    COUNT=""
    LABEL_PAD_R=0
else
    case "$COUNT" in
        [6-9]|[1-9][0-9]*)
            COLOR=$RED
            ;;
        [3-5])
            COLOR=$ORANGE
            ;;
        [1-2])
            COLOR=$YELLOW
            ;;
        0)
            COLOR=$GREEN
            COUNT=""
            LABEL_PAD_R=0
            ;;
    esac
fi

sketchybar --set $NAME label="$COUNT" icon.string="$ICON" icon.color="$COLOR" label.color="$COLOR" label.padding_right="$LABEL_PAD_R"
