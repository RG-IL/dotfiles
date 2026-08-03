#!/usr/bin/env bash
# Raw Wi-Fi state for the shared status files, consumed by both tmux
# (wifi_combined.sh) and sketchybar (wifi.lua). Emits: ssid|signal|rate
# where signal is the RSSI magnitude (e.g. 77 for -77 dBm) and rate is the
# transmit rate in Mbps. SSID is redacted on macOS 26+, so it is always empty.
# Uses the compiled CoreWLAN helper (wifi_state), ~10ms warm, so the daemon
# can refresh this every second. Runs from the launchd status daemon so the
# CoreWLAN reads are not attributed to any UI app.
state="$("$HOME/.config/sketchybar/helpers/wifi_state" 2>/dev/null)"
echo "|${state}"
