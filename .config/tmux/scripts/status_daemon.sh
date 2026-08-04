#!/usr/bin/env bash
# Status daemon: computes status values once per interval and publishes them as
#   - raw state files in /tmp/status/* consumed by BOTH tmux and sketchybar
#   - tmux user options (@bubble_*) so the status bar renders with zero forks
# Managed by launchd (com.raphael.tmux-status) so the metric scripts run under
# launchd's responsibility chain instead of the UI apps — tccd does not
# re-validate Ghostty's or sketchybar's signature for these. Skips the tmux
# push when no tmux server is running; state files are written regardless.
#
# Cadence: cpu/mem/temp/wifi every tick; bluetooth/battery every 5 ticks;
# caffeinate every 30; brew packages every 600. (Wifi uses a ~10ms CoreWLAN
# helper; blueutil / pmset / brew are the expensive slow-changing reads.)
INTERVAL="${1:-1}"
FAST_EVERY="${2:-1}"
SLOW_EVERY="${3:-5}"

CFG="$HOME/.config/tmux"
SYSTAT="$CFG/plugins/tmux-plugin-sysstat/scripts"
TMUXCPU="$CFG/plugins/tmux-cpu/scripts"
TMUXWIFI="$CFG/plugins/tmux-wifi/scripts"
TMUXBATT="$CFG/plugins/tmux-battery/scripts"
SCRIPTS="$CFG/scripts"
SB_HELPERS="$HOME/.config/sketchybar/helpers"
STATUS_DIR="/tmp/status"

mkdir -p "$STATUS_DIR"
bt_file="$STATUS_DIR/bt"
wifi_file="$STATUS_DIR/wifi"
batt_file="$STATUS_DIR/batt"
caffeinate_file="$STATUS_DIR/caffeinate"
packages_file="$STATUS_DIR/packages"
packages_list_file="$STATUS_DIR/packages_list"
refresh_running="$STATUS_DIR/packages_refresh_running"
upgrade_requested="$STATUS_DIR/upgrade_requested"
upgrade_running="$STATUS_DIR/upgrade_running"

cycle=0
while true; do
  cycle=$((cycle + 1))
  # Measure the cycle's work time and sleep only the remainder, so the tick
  # cadence stays at INTERVAL (1s) even when a slow sibling (blueutil, brew)
  # stretches one cycle.
  t0="$(perl -MTime::HiRes=time -e 'printf q{%.4f}, time')"

  # Wi-Fi uses a ~10ms CoreWLAN helper, so it refreshes every tick (1s).
  "$SCRIPTS/wifi_info.sh" > "$wifi_file.tmp" 2>/dev/null && mv "$wifi_file.tmp" "$wifi_file"
  if ((cycle % SLOW_EVERY == 0)); then
    "$SCRIPTS/bluetooth_devices.sh" > "$bt_file.tmp" 2>/dev/null && mv "$bt_file.tmp" "$bt_file"
    "$SCRIPTS/battery_info.sh" > "$batt_file.tmp" 2>/dev/null && mv "$batt_file.tmp" "$batt_file"
  fi
  if ((cycle % 30 == 0)); then
    "$SCRIPTS/caffeinate_info.sh" > "$caffeinate_file.tmp" 2>/dev/null && mv "$caffeinate_file.tmp" "$caffeinate_file"
  fi
  if ((cycle % 600 == 0)); then
    if [[ ! -f "$refresh_running" ]]; then
      touch "$refresh_running"
      nohup "$SCRIPTS/refresh_packages.sh" >/dev/null 2>&1 &
    fi
  fi

  if [[ -f "$upgrade_requested" && ! -f "$upgrade_running" ]]; then
    mv "$upgrade_requested" "$upgrade_running"
    nohup "$SCRIPTS/upgrade_packages.sh" >/dev/null 2>&1 &
  fi

  if tmux has-session 2>/dev/null; then
    tmux set-option -g @bubble_cpu_val "$("$SYSTAT/cpu.sh")" \
      \; set-option -g @bubble_mem_val "$("$SYSTAT/mem.sh")" \
      \; set-option -g @bubble_temp_val "$("$TMUXCPU/cpu_temp.sh")" \
      \; set-option -g @bubble_bt_val "$("$SCRIPTS/bluetooth.sh" --module)" \
      \; set-option -g @bubble_wifi_val "$("$TMUXWIFI/wifi_combined.sh")" \
      \; set-option -g @bubble_batt_icon "$("$TMUXBATT/battery_icon.sh")" \
      \; set-option -g @bubble_batt_pct "$("$TMUXBATT/battery_percentage.sh")"
  fi

  sleep "$(perl -MTime::HiRes=time -e "\$t = $INTERVAL - (time - $t0); \$t = 0.05 if \$t < 0.05; printf q{%.4f}, \$t")"
done
