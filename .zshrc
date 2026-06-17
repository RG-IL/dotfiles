# Auto-attach to latest tmux session (only with a real TTY, not in VSCode/Terminal.app)
if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -t 0 ]] && [[ "$TERM_PROGRAM" != "vscode" ]] && [[ "$TERM_PROGRAM" != "Apple_Terminal" ]] && command -v tmux >/dev/null 2>&1; then
  # Fast path: only query tmux if server is already running
  local socket="${TMUX_TMPDIR:-/private/tmp}/tmux-$(id -u)/default"
  if [[ -S "$socket" ]]; then
    last_session=$(tmux ls -F '#{session_name}' 2>/dev/null | grep -v '^scratch$' | tail -1)
    if [[ -n "$last_session" ]]; then
      exec tmux attach-session -t "$last_session"
    fi
  fi
  exec tmux new-session -s main 2>/dev/null
fi

export PATH="/Library/Frameworks/Python.framework/Versions/3.14/bin:$PATH"
export BREW_PREFIX="/opt/homebrew"

# Autoload functions on first use instead of defining at startup
fpath=(~/.config/zsh/functions $fpath)
autoload -Uz ai anifetch_with_timeout coddy csc iv ls rs רד spl y _atuin_ai_from_buffer

[[ -d ~/.cache/zsh ]] || mkdir -p ~/.cache/zsh
setopt SHARE_HISTORY




if [[ ! -f ~/.cache/zsh/omp-init.zsh || ~/.ZSHThemes.json -nt ~/.cache/zsh/omp-init.zsh ]]; then
  oh-my-posh init zsh --config ~/.ZSHThemes.json > ~/.cache/zsh/omp-init.zsh
fi
source ~/.cache/zsh/omp-init.zsh

export TERM=xterm-256color

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f2d3b7"

[ -f ~/.cache/zsh/fzf-init.zsh ] || fzf --zsh > ~/.cache/zsh/fzf-init.zsh
source ~/.cache/zsh/fzf-init.zsh

bindkey '^I'      autosuggest-accept
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(buffer-empty bracketed-paste accept-line push-line-or-edit)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true
export FZF_COMPLETION_TRIGGER=''
bindkey '^[' fzf-completion
bindkey '^[^L' forward-word

source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
export BW_SESSION="tkBGDkMDkTSG8vck2o09kecMbBDrc8GpULijN6wPPFvyPfMyuOaq6XipV5tGfbDedZJPS1SERTto+anWoIc1EQ=="
# Insert mode = bar, Normal mode = block (vim-like)

alias cd="z"
if [[ ! -f ~/.cache/zsh/zx-init.zsh ]]; then
  zoxide init zsh > ~/.cache/zsh/zx-init.zsh
fi
source ~/.cache/zsh/zx-init.zsh
alias oc="opencode"



# Defer slow plugins to first prompt
typeset -a _zsh_defer_plugins
_zsh_defer_plugins=(
  "$BREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  "$HOME/.cache/zsh/at-init.zsh"
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

. "$HOME/.atuin/bin/env"

if [[ ! -f ~/.cache/zsh/at-init.zsh ]]; then
  atuin init zsh > ~/.cache/zsh/at-init.zsh
fi
# Sourced via deferred plugins below

# play Spotify liked songs (starts hidden, no window)
# Atuin AI: type a prompt, then hit Ctrl+O to send it to AI
zle -N _atuin_ai_from_buffer
bindkey '^[^A' _atuin_ai_from_buffer
fuck() { atuin ai inline "look at my last command and fix any typos or errors"; }

export FZF_DEFAULT_OPTS=" \
--color=fg:#C6D0F5,header:#E78284,info:#CA9EE6,pointer:#F2D5CF \
--color=marker:#BABBF1,fg+:#C6D0F5,prompt:#CA9EE6,hl+:#E78284 \
--color=selected-bg:#51576D \
--color=border:#737994,label:#C6D0F5"

export PATH=$PATH:/Users/raphael/.spicetify

# csc - watches clipboard, saves each copy, auto-creates .cs files when
#       filenames (ending with " X" or " x") are detected
CSC_DIR=~/.cache/csc
# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
# Run anifetch in all shells EXCEPT sesh sessions that have a startup_command
if ! [[ -n "$TMUX" ]] || ! grep -A2 "name = \"$(tmux display-message -p '#{session_name}' 2>/dev/null)\"" ~/.config/sesh/sesh.toml 2>/dev/null | grep -q "startup_command"; then
  anifetch_with_timeout 8
fi
# Reset cursor to steady bar on every prompt (fixes block cursor after exiting nvim)
_reset_cursor() { printf '\033[6 q' >/dev/tty }
precmd_functions+=(_reset_cursor)

alias cool="anifetch --framerate 30 --playback-rate 30 -ca '--symbols brail --fg-only' -w 90 -H 20  /Users/raphael/.config/fastfetch/ghostty-ani.mov"
