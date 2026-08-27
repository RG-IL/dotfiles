export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$HOME/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin:$PATH"

source ~/.config/zsh/completions.zsh
source ~/.config/zsh/keybinds.zsh
source ~/.config/zsh/aliases.zsh

if [[ ! -f ~/.cache/zsh/zx-init.zsh ]]; then
  zoxide init zsh > ~/.cache/zsh/zx-init.zsh
fi
source ~/.cache/zsh/zx-init.zsh

# Defer slow plugins to first prompt
typeset -a _zsh_defer_plugins
_zsh_defer_plugins=(
  "$HOME/.cache/zsh/at-init.zsh"
  "/usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
)
_load_deferred_plugins() {
  local p
  for p in $_zsh_defer_plugins; do source "$p"; done
  unset _zsh_defer_plugins
  unfunction _load_deferred_plugins
}
precmd_functions+=(_load_deferred_plugins)

export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
export EDITOR="nvim"
export VISUAL="nvim"

if [[ ! -f ~/.cache/zsh/at-init.zsh ]]; then
  atuin init zsh > ~/.cache/zsh/at-init.zsh
fi
# atuin env sourced via deferred plugins above

# Atuin AI: type a prompt, then hit Ctrl+O to send it to AI
zle -N _atuin_ai_from_buffer
bindkey '^[^A' _atuin_ai_from_buffer
fuck() { atuin ai inline "look at my last command and fix any typos or errors"; }

# Reset cursor to steady bar on every prompt (fixes block cursor after exiting nvim)
_reset_cursor() { printf '\033[6 q' >/dev/tty }
precmd_functions+=(_reset_cursor)

# opencode
export PATH=$HOME/.opencode/bin:$PATH
export OPENCODE_PORT=4096
