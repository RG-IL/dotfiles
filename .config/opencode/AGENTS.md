# Agent Instructions

### rules

Never, and I mean never, remove JumpGame and JumpGame_Github
ALWAYS USE UNSLOP SKILL

### sudo

Every time you need sudo, first check if passwordless sudo is enabled: `sudo -n true`. If it fails, run `menu-term menu-sudo-passwordless` (the Passwordless Sudo entry in my caelestia menu). It opens a floating terminal window where I confirm the prompt, and passwordless sudo turns on for 15 minutes. Poll `sudo -n true` every few seconds (up to ~3 minutes) until it passes, then run the sudo command. If it still fails after that, stop and tell me instead of trying workarounds. Never ask me to type a sudo password in this session and never edit /etc/sudoers yourself.
