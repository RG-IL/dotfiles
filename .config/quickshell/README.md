# Shell setup

Two shell trees live here; both are quickshell configs named by their directory.

## Daily driver — the PR checkout

`caelestia` is a symlink to `~/Projects/caelestia-shell`, the `feat/launcher-menu`
branch of caelestia-shell (PR #2359). All the usual commands are unchanged —
`caelestia shell -d`, `-k`, `-r -d`, `toaster ...` — and now run the PR tree.
Because that tree ships its own Caelestia QML modules, `hyprland/env.lua` points
`QML2_IMPORT_PATH` and `CAELESTIA_LIB_DIR` at its `build/` directory.

- `caelestia-shell-update` — pull the branch, rebuild, restart the daily shell.
  Needs `cmake` and `ninja` (installed explicitly with pacman).
- `caelestia-shell-pr` — switch back to the PR shell after using the backup.

## Backup — the local/package tree

`caelestia-local/` is the old daily tree: symlinks into
`/etc/xdg/quickshell/caelestia` plus the personal launcher and overlay
overrides. It uses the installed caelestia-shell modules.

- `caelestia-shell-local` — stop the PR shell and start this one. It unsets the
  PR import paths so the installed modules are used.
- `sync-upstream.sh` (inside that directory) re-links new upstream files after
  a caelestia-shell package update.
