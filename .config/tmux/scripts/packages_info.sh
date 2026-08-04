#!/usr/bin/env bash
# Raw brew-outdated report for sketchybar (packages.lua via package_monitor.sh).
# Emits the updatable-formula count on line 1, then one `name|installed|latest`
# line per outdated formula, or 0 on failure. The daemon writes line 1 to
# /tmp/status/packages and the rest to /tmp/status/packages_list. The python
# wrapper resets SIGCHLD before spawning brew, because a SIG_IGN disposition
# inherited from a shell crashes Homebrew's portable Ruby. Runs from the
# launchd status daemon on a slow cadence (brew under launchd, never under
# sketchybar).
# --formula: default `brew outdated` also evaluates auto-updating casks via their
# app bundle version, so a cask that hasn't self-updated yet shows as a phantom
# "1" that `brew upgrade` can never clear. Formula-only matches what brew
# upgrade can actually update.
# No HOMEBREW_NO_AUTO_UPDATE: with it set, the count reads only the local API
# cache, which brew refreshes only when the user runs brew. That made the
# widget report "up to date" indefinitely after the cache aged past brew's
# auto-update window. Letting brew auto-update keeps the check ~1s when the
# cache is fresh (24h window) and refreshes it in one slow pass when stale.
# The try/except below guarantees a numeric exit 0, so a stale count file can
# never persist.
/usr/bin/python3 -c '
import os, signal, subprocess, re

signal.signal(signal.SIGCHLD, signal.SIG_DFL)
try:
    r = subprocess.run(
        ["/opt/homebrew/bin/brew", "outdated", "--formula", "--verbose"],
        capture_output=True,
        text=True,
    )
except Exception:
    print(0)
    raise SystemExit(0)
if r.returncode != 0:
    print(0)
else:
    lines = [l for l in r.stdout.splitlines() if l.strip()]
    print(len(lines))
    for l in lines:
        m = re.match(r"^([^ (]+) \(([^)]*)\) < (.+)$", l)
        if m:
            name, installed, latest = m.groups()
            print(f"{name}|{installed}|{latest}")
        else:
            print(f"{l}| | ")
'
