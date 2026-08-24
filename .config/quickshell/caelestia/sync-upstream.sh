#!/usr/bin/env bash

# Mirrors the packaged caelestia shell (/etc/xdg/quickshell/caelestia) into
# this directory using symlinks, so this tree forms a complete quickshell
# config that always tracks the installed package.
#
# Real files here win over upstream links — that is how the customizations
# (MenuService, launcher Content/ContentList, menu-overlays, ServiceLoader)
# survive caelestia-shell updates: pacman only ever writes to /etc/xdg, and
# everything not overridden follows those updates through the symlinks.
#
# Run this:
#   - on a new machine, after stowing dotfiles AND installing caelestia-shell
#   - after upgrading caelestia-shell (links new upstream files into the tree)
#
# Never edit shell.qml or any symlinked file here; add an override file
# instead, or the change will be silently shadowed back on the next sync.

set -euo pipefail

UPSTREAM="/etc/xdg/quickshell/caelestia"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d $UPSTREAM ]]; then
  echo "caelestia-shell is not installed ($UPSTREAM missing)" >&2
  exit 1
fi

# Remove symlinks pointing into upstream at targets that no longer exist.
while IFS= read -r -d '' p; do
  target="$(readlink "$p")"
  if [[ $target == "$UPSTREAM"* && ! -e $target ]]; then
    rm -- "$p"
    echo "pruned   ${p#"$HERE"/} (gone from package)"
  fi
done < <(find . -type l -print0)

sync_tree() {
  local src="$1" dst="$2" name target
  mkdir -p -- "$dst"

  for entry in "$src"/*; do
    name="$(basename "$entry")"
    target="$dst/$name"

    if [[ -L $target ]]; then
      if [[ $(readlink "$target") != "$entry" ]]; then
        ln -sfn -- "$entry" "$target"
        echo "relinked ${target#"$HERE"/}"
      fi
    elif [[ -e $target ]]; then
      if [[ -d $entry && -d $target ]]; then
        sync_tree "$entry" "$target"
      else
        echo "kept     ${target#"$HERE"/} (override)"
      fi
    else
      ln -s -- "$entry" "$target"
      echo "linked   ${target#"$HERE"/}"
    fi
  done
}

sync_tree "$UPSTREAM" "$HERE"

echo
echo "done — apply with: qs -c caelestia kill; sleep .3; caelestia shell -d"
