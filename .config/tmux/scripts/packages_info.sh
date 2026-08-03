#!/usr/bin/env bash
# Raw brew-outdated count for sketchybar (packages.lua via package_monitor.sh).
# Emits the number of updatable formulas, or 0 on failure. The python wrapper
# resets SIGCHLD before spawning brew, because a SIG_IGN disposition inherited
# from a shell crashes Homebrew's portable Ruby. Runs from the launchd status
# daemon on a slow cadence (brew under launchd, never under sketchybar).
# --formula: default `brew outdated` also evaluates auto-updating casks via
# their app bundle version, so a cask that hasn't self-updated yet shows as a
# phantom "1" that `brew upgrade` can never clear. Formula-only matches what
# brew upgrade can actually update. HOMEBREW_NO_AUTO_UPDATE keeps the check
# fast and deterministic (no mid-update tap state).
/usr/bin/python3 -c '
import os, signal, subprocess

signal.signal(signal.SIGCHLD, signal.SIG_DFL)
env = dict(os.environ)
env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
r = subprocess.run(
    ["/opt/homebrew/bin/brew", "outdated", "--formula", "--quiet"],
    capture_output=True,
    text=True,
    env=env,
)
if r.returncode != 0:
    print(0)
else:
    print(len([line for line in r.stdout.splitlines() if line.strip()]))
'
