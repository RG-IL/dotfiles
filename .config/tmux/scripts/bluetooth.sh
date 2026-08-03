#!/usr/bin/env bash
# Bluetooth status for tmux status bar (macOS)
# Reads the shared raw state from /tmp/status/bt (written by the launchd
# status daemon from bluetooth_devices.sh) instead of running blueutil, so
# tccd never re-validates this app chain for the periodic poll.
# Output:
#   --icon:    nerd font icon (󰂲 off, 󰂰 no devices, or device icon)
#   --display: device text (empty when off/no devices)
#   --module:  icon + text combined (no trailing space when empty)
#   (no args): "type|display text" (backward compat)

BT_FILE="/tmp/status/bt"

_detect_type() {
    local name="$1"
    local lower
    lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    case "$lower" in
    *buds* | *ear* | *headphone* | *headset*) echo "headphone" ;;
    *keyboard* | *keys*) echo "keyboard" ;;
    *mouse*) echo "mouse" ;;
    *speaker* | *speak*) echo "speaker" ;;
    *phone* | *iphone* | *galaxy* | *pixel*) echo "phone" ;;
    *trackpad* | *magic\ trackpad*) echo "trackpad" ;;
    *watch*) echo "watch" ;;
    *tablet* | *ipad*) echo "tablet" ;;
    *gamepad* | *joystick* | *controller*) echo "gamepad" ;;
    *printer*) echo "printer" ;;
    *) echo "generic" ;;
    esac
}

_icon_for_type() {
    case "$1" in
    headphone) echo "󰋋" ;; keyboard) echo "" ;;
    mouse) echo "" ;; speaker) echo "󰓃" ;;
    phone) echo "󰀲" ;; trackpad) echo "" ;;
    watch) echo "󰖉" ;; tablet) echo "󰩼" ;;
    gamepad) echo "" ;; printer) echo "󰐪" ;;
    *) echo "󰂯" ;;
    esac
}

main() {
    local mode="${1:-}"

    local data power
    data=$(cat "$BT_FILE" 2>/dev/null)
    power=$(printf '%s\n' "$data" | head -1)
    [[ "$power" == "1" ]] || {
        [[ "$mode" == "--icon" || "$mode" == "--module" ]] && echo "󰂲"
        return
    }

    # Parse the shared device lines (addr|name|connected|battery); only
    # connected devices are displayed, in the file's address order.
    local names=() macs=() bats=()
    while IFS='|' read -r mac name conn bat; do
        [[ -n "$mac" && -n "$name" && "$conn" == "1" ]] || continue
        names+=("$name")
        macs+=("$mac")
        bats+=("$bat")
    done <<<"$(printf '%s\n' "$data" | tail -n +2 | grep -v '^---$' | grep -v '^$')"
    [[ ${#names[@]} -eq 0 ]] && {
        [[ "$mode" == "--icon" || "$mode" == "--module" ]] && echo ""
        return
    }

    local primary_type
    primary_type=$(_detect_type "${names[0]}")
    primary_type=$(echo "$primary_type" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g')

    # --icon mode: output mapped icon
    if [[ "$mode" == "--icon" ]]; then
        _icon_for_type "$primary_type"
        return
    fi

    # Build display text
    local parts=()
    for i in "${!names[@]}"; do
        local name="${names[$i]}"
        local dev_type
        dev_type=$(_detect_type "$name")
        # Skip battery for devices with physical batteries (mice, keyboards, etc.)
        case "$dev_type" in
        mouse | keyboard | trackpad)
            parts+=("${name}")
            ;;
        *)
            local bat="${bats[$i]}"
            if [[ -n "$bat" ]]; then
                parts+=("${name} (${bat}%)")
            else
                parts+=("${name}")
            fi
            ;;
        esac
    done
    local display_text
    if [[ ${#parts[@]} -eq 1 ]]; then
        display_text="${parts[0]}"
    else
        display_text="${parts[0]} +$((${#parts[@]} - 1))"
    fi

    # --display mode: output just text
    if [[ "$mode" == "--display" ]]; then
        echo "$display_text"
        return
    fi

    # --module mode: icon + text combined (no trailing space when empty)
    if [[ "$mode" == "--module" ]]; then
        local icon
        icon=$(_icon_for_type "$primary_type")
        if [[ -n "$display_text" ]]; then
            echo "${icon} ${display_text}"
        else
            echo "$icon"
        fi
        return
    fi

    # No args: backward compat "type|display"
    echo "${primary_type}|${display_text}"
}

main "$@"
