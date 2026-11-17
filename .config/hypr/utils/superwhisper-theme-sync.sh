#!/bin/sh
# Copy the active caelestia colour scheme into Superwhisper's theme file, so
# the recording edge glow follows the wallpaper-driven Material You palette.
# A systemd .path unit on scheme/current.lua runs this on every scheme change.
# Without this file Superwhisper falls back to its own default accent colour.

scheme="$HOME/.config/hypr/scheme/current.lua"
theme="$HOME/.local/state/omarchy/current/theme/colors.toml"

[ -f "$scheme" ] || exit 0

colour() { grep -oP "^[[:space:]]*$1[[:space:]]*=[[:space:]]*\"\K[0-9a-fA-F]{6}" "$scheme" || true; }

accent=$(colour primary) || exit 0
[ -n "$accent" ] || exit 0

mkdir -p "$(dirname "$theme")"
{
    echo "accent = \"#$accent\""
    bg=$(colour background)
    [ -n "$bg" ] && echo "background = \"#$bg\""
    fg=$(colour onSurface)
    [ -n "$fg" ] && echo "foreground = \"#$fg\""
} > "$theme"

# Push the new colours into a running service; a fresh start reads the file
# from disk anyway.
systemctl --user is-active --quiet superwhisper.service && superwhisper audio reload || true
