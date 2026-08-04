#!/usr/bin/env bash
# Populates the @bubble_* tmux options at server start so the status bar shows
# real values on its first draw, instead of waiting for the launchd status
# daemon's next 1s tick (which averages 0.5s after a fresh `tmux new-session`).
# Mirrors the daemon's push block exactly; the daemon keeps the options fresh
# afterwards. Run via `run-shell -b` so server start is never blocked.
CFG="$HOME/.config/tmux"
SYSTAT="$CFG/plugins/tmux-plugin-sysstat/scripts"
TMUXCPU="$CFG/plugins/tmux-cpu/scripts"
TMUXWIFI="$CFG/plugins/tmux-wifi/scripts"
TMUXBATT="$CFG/plugins/tmux-battery/scripts"
SCRIPTS="$CFG/scripts"

tmux set-option -g @bubble_cpu_val "$("$SYSTAT/cpu.sh")" \
  \; set-option -g @bubble_mem_val "$("$SYSTAT/mem.sh")" \
  \; set-option -g @bubble_temp_val "$("$TMUXCPU/cpu_temp.sh")" \
  \; set-option -g @bubble_bt_val "$("$SCRIPTS/bluetooth.sh" --module)" \
  \; set-option -g @bubble_wifi_val "$("$TMUXWIFI/wifi_combined.sh")" \
  \; set-option -g @bubble_batt_icon "$("$TMUXBATT/battery_icon.sh")" \
  \; set-option -g @bubble_batt_pct "$("$TMUXBATT/battery_percentage.sh")"
