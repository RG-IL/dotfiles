#!/usr/bin/env bash
# Bluetooth status for tmux status bar (macOS)
# Output:
#   --icon:    nerd font icon (󰂲 off, 󰂰 no devices, or device icon)
#   --display: device text (empty when off/no devices)
#   --module:  icon + text combined (no trailing space when empty)
#   (no args): "type|display text" (backward compat)

_pmset_battery() {
    local name="$1" pmset_out="$2"
    [[ -z "$pmset_out" ]] && return
    echo "$pmset_out" | grep -F "$name" | grep -oE '[0-9]+%' | head -1 | tr -d '%'
}

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

    # Fast power check
    if command -v blueutil &>/dev/null; then
        [[ "$(blueutil -p 2>/dev/null)" == "1" ]] || {
            [[ "$mode" == "--icon" || "$mode" == "--module" ]] && echo "󰂲"
            return
        }
    else
        [[ "$mode" == "--icon" || "$mode" == "--module" ]] && echo "󰂲"
        return
    fi

    # blueutil 2.13.0 --connected is buggy on macOS 14+ (returns empty).
    # Workaround: iterate paired devices and check each via --info.
    local names=() macs=()
    local paired_lines
    paired_lines=$(blueutil --paired 2>/dev/null | sort -u)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local mac=""
        [[ "$line" =~ address:\ ([0-9a-fA-F-]+) ]] && mac="${BASH_REMATCH[1]}"
        [[ -z "$mac" ]] && continue
        local info
        info=$(blueutil --info "$mac" 2>/dev/null)
        if echo "$info" | grep -q ", connected"; then
            local name=""
            [[ "$info" =~ name:\ \"([^\"]+)\" ]] && name="${BASH_REMATCH[1]}"
            [[ -z "$name" ]] && continue
            names+=("$name")
            macs+=("$mac")
        fi
    done <<<"$paired_lines"
    [[ ${#names[@]} -eq 0 ]] && {
        [[ "$mode" == "--icon" || "$mode" == "--module" ]] && echo ""
        return
    }

    local pmset_out
    pmset_out=$(pmset -g accps 2>/dev/null)
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
            local bat=""
            bat=$(_pmset_battery "$name" "$pmset_out")
            if [[ -z "$bat" && -n "${macs[$i]}" ]]; then
                bat=$(blueutil --info "${macs[$i]}" 2>/dev/null | grep -i battery | grep -oE '[0-9]+' | head -1)
            fi
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
