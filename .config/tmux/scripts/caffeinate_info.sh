#!/usr/bin/env bash
# Raw caffeinate-assertion state for sketchybar (caffeinate.lua). Emits the PID
# of an active `caffeinate` assertion, or nothing. Runs from the launchd status
# daemon on a slow cadence.
pmset -g assertions 2>/dev/null | grep caffeinate | awk '{print $2}' | cut -d '(' -f1 | head -n 1
