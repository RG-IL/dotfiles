---
name: app-cleaner
description: >-
  Use when the user asks to uninstall, delete, remove, wipe, or clean an application
  completely. This skill goes beyond just trashing the .app bundle — it finds and
  removes all support files, caches, preferences, logs, containers, saved state,
  crash reports, and sandbox data scattered across the filesystem.
---

# App Cleaner

When the user asks to completely remove an application, follow these steps.

## 1. Identify the app name

The user may refer to the app by its display name (e.g. "Spotify", "Visual Studio Code")
or its bundle name ("Spotify.app"). Normalize to the bundle name (strip ".app" if given).

## 2. Find the main app bundle

Search these paths for the `.app` bundle:

- `/Applications/<Name>.app`
- `~/Applications/<Name>.app`
- `/System/Applications/<Name>.app`
- `/System/Library/CoreServices/<Name>.app`

If not found, use `mdfind "kMDItemContentType == 'com.apple.application-bundle' && kMDItemFSName == '<Name>.app'"`.

**If the app is not installed, tell the user and stop.**

## 3. Gather all related paths

### 3a. Use Spotlight

Run: `mdfind "kMDItemFSName == '<Name>*' || kMDItemContentCreationDate >= \$time.this_week"` — but more practically, run:

```
mdfind "<Name>"
```

and filter results to paths that clearly belong to the app (the user can confirm).

### 3b. Check common directories for any file/folder whose name contains the app name

Check these locations for files or directories matching `*<Name>*` (case-insensitive):

**User scope:**
- `~/Library/Application Support/`
- `~/Library/Caches/`
- `~/Library/Preferences/`
- `~/Library/Preferences/ByHost/`
- `~/Library/Logs/`
- `~/Library/Containers/`
- `~/Library/Group Containers/`
- `~/Library/Saved Application State/`
- `~/Library/LaunchAgents/`
- `~/Library/WebKit/`
- `~/Library/Cookies/`
- `~/Library/Services/`
- `~/Library/Audio/Plug-Ins/`
- `~/Library/Fonts/`
- `~/Library/Screen Savers/`
- `~/Library/Internet Plug-Ins/`
- `~/Library/QuickLook/`
- `~/Library/Spotlight/`
- `~/Library/Input Methods/`
- `~/Library/Keyboard Layouts/`
- `~/Library/PDF Services/`
- `~/Library/ScriptingAdditions/`
- `~/Library/Contextual Menu Items/`
- `~/Library/Application Scripts/`
- `~/.local/share/`
- `~/.config/`
- `~/.cache/`

**System scope (requires `sudo`, ask user first):**
- `/Library/Application Support/`
- `/Library/Caches/`
- `/Library/Preferences/`
- `/Library/Logs/`
- `/Library/LaunchAgents/`
- `/Library/LaunchDaemons/`
- `/Library/StartupItems/`
- `/Library/Extensions/`
- `/Library/PrivilegedHelperTools/`
- `/Library/Internet Plug-Ins/`
- `/Library/Spotlight/`
- `/Library/QuickLook/`
- `/Library/Audio/Plug-Ins/`
- `/Library/CFMSupport/`
- `/Library/Frameworks/`
- `/Library/Dropbox/`

### 3c. Use `which` and `type` commands

If the app installs CLI tools:

```
which <name> 2>/dev/null; type <name> 2>/dev/null
```

Also check `/usr/local/bin/`, `/opt/homebrew/bin/`, `/opt/local/bin/` for any
matching binaries.

### 3d. Check Homebrew/Cask (if applicable)

```
brew list --cask 2>/dev/null | grep -i "<name>"
brew list 2>/dev/null | grep -i "<name>"
```

## 4. Present the list to the user

Show the user all discovered paths grouped by category and ask for confirmation
before deleting anything.

## 5. Delete everything

After receiving explicit confirmation:

1. `rm -rf` each user-scope path
2. If system-scope paths were found and user confirmed with `sudo`: `sudo rm -rf`
3. If Homebrew/Cask installed it: `brew uninstall --cask <name>` or `brew uninstall --formula <name>`
4. `mdfind "<Name>"` — do a final check for any leftovers and report to the user

## Important safety rules

- **Always ask for confirmation** before removing anything.
- **Never use `sudo`** without explicit user approval.
- If the app is a built-in macOS app (`/System/Applications/` or `/System/Library/`),
  warn the user and refuse unless they explicitly insist.
- Do NOT delete files outside these standard paths without asking first.
- If `mdfind` returns hundreds of false positives (e.g. the name is generic like
  "Music" or "Notes"), rely more on the well-known directory scan and less on
  spotlight results.
- After deletion, summarize what was removed and the total freed space.
