#!/usr/bin/env bash

# Caelestia menu installer.
# - makes all bin/ scripts executable
# - asks for the editor used by menu-edit (stored in menu.conf,
#   changeable later by editing that file)
# - checks optional runtime dependencies

set -euo pipefail

MENU_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF="$MENU_DIR/menu.conf"

bold=$'\e[1m'
reset=$'\e[0m'

echo "${bold}Caelestia menu installer${reset}"

# --- editor choice -----------------------------------------------------------

current=""
[[ -f $CONF ]] && source "$CONF"
default="${MENU_EDITOR:-nvim}"

echo
echo "Which editor should open config files? (terminal editor, e.g. nvim, vi, nano)"
read -rp "Editor [$default]: " chosen
chosen="${chosen:-$default}"
command -v "${chosen%% *}" >/dev/null 2>&1 || {
  echo "warning: '$chosen' not found in PATH; keeping it anyway" >&2
}

cat > "$CONF" <<EOF
# Editor used by menu-edit. Change here anytime.
# Leave empty/commented to fall back to \$EDITOR, then nvim.
MENU_EDITOR="$chosen"
EOF
echo "wrote $CONF (MENU_EDITOR=\"$chosen\")"

# --- permissions -------------------------------------------------------------

chmod +x "$MENU_DIR"/bin/*
echo "made bin/* executable"

# --- dependency check --------------------------------------------------------

missing=()
for dep in ghostty jq systemctl notify-send wl-copy; do
  command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if ((${#missing[@]})); then
  echo "warning: missing optional dependencies: ${missing[*]}" >&2
  echo "some menu actions may not work without them"
fi

# --- hyprland config sanity --------------------------------------------------

HYPR_CONF="$HOME/.config/hypr/hyprland.lua"
[[ -f $HYPR_CONF ]] || echo "note: $HYPR_CONF not found; Hyprland entries will fall back to an error until it exists"

echo
echo "done. restart the shell with: caelestia shell -d (or your usual method)"
