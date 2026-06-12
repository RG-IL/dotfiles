
## [ERR-20250612-001] copilot_lsp_auth_header

**Logged**: 2026-06-12T12:35:00Z
**Priority**: high
**Status**: pending
**Area**: config

### Summary
Copilot LSP crashes with exit code 143 (SIGTERM) due to `ERR_INVALID_CHAR` in Authorization header.

### Error
```
Client copilot quit with exit code 143 and signal 0.
[GithubAvailableEmbeddingTypes] Error fetching available embedding types TypeError [ERR_INVALID_CHAR]: Invalid character in header content ["Authorization"]
```

### Context
- copilot.lua v3.0.0 (commit `6afee36`) removed `apps.json` support
- The JS backend still makes API calls and tries to use an Authorization header with the old token
- The `apps.json` file at `~/.config/github-copilot/apps.json` has a valid token but the new auth flow uses `auth.db`

### Suggested Fix
1. Delete `~/.config/github-copilot/apps.json` (no longer used)
2. Re-authenticate with `:Copilot auth` or `lua require("copilot.auth").signin()`

### Metadata
- Reproducible: yes
- Related Files: ~/.config/github-copilot/apps.json, ~/.local/share/nvim/lazy/copilot.lua
- Tags: copilot, lsp, auth

---
