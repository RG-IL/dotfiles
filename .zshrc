# Auto-attach to latest tmux session (only with a real TTY, not in VSCode/Terminal.app)
if [[ -n "$NVIM_QUICK_ACTION" ]] && command -v tmux >/dev/null 2>&1; then
  local file="$NVIM_QUICK_FILE"
  unset NVIM_QUICK_ACTION NVIM_QUICK_FILE

  if [[ -S /tmp/nvim-editor.sock ]]; then
    /opt/homebrew/bin/nvim --server /tmp/nvim-editor.sock --remote "$file"
  elif tmux has-session -t editor 2>/dev/null; then
    tmux send-keys -t "editor" " /opt/homebrew/bin/nvim --listen /tmp/nvim-editor.sock \"$file\"" Enter
    exec tmux attach-session -t editor
  else
    exec tmux new-session -s editor "/opt/homebrew/bin/nvim --listen /tmp/nvim-editor.sock \"$file\"; exec /bin/zsh -l"
  fi
fi

if [[ $- == *i* ]] && [[ -z "$TMUX" ]] && [[ -t 0 ]] && [[ "$TERM_PROGRAM" != "vscode" ]] && [[ "$TERM_PROGRAM" != "Apple_Terminal" ]] && command -v tmux >/dev/null 2>&1; then
  last_session=$(tmux ls -F '#{session_name}' 2>/dev/null | grep -v '^scratch$' | tail -1)
  if [[ -n "$last_session" ]]; then
    exec tmux attach-session -t "$last_session"
  fi
  # No reachable sessions — clean up stale socket if present, then start fresh
  local socket="${TMUX_TMPDIR:-/private/tmp}/tmux-$(id -u)/default"
  [[ -S "$socket" ]] && rm -f "$socket"
  exec tmux new-session -s main 2>/dev/null
fi

export PATH="/Library/Frameworks/Python.framework/Versions/3.14/bin:$PATH"
export BREW_PREFIX="/opt/homebrew"

# Autoload functions on first use instead of defining at startup
fpath=(~/.config/zsh/functions $fpath)
autoload -Uz ai coddy csc iv ls rs רד spl y _atuin_ai_from_buffer

# Show animated system info early (compiled C — instant startup)
if ! [[ -n "$TMUX" ]] || ! grep -A2 "name = \"$(tmux display-message -p '#{session_name}' 2>/dev/null)\"" ~/.config/sesh/sesh.toml 2>/dev/null | grep -q "startup_command"; then
  ~/.config/zsh/ghost
fi

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
alias oc='opencode'



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
--color=border:#737994,label:#C6D0F5 \
--bind 'tab:down,btab:up'"

# fzf custom completions — subcommands + flags (trigger: Alt after command + space)

# awk helper: extract --word and -X flags from help text
__fzf_flags() {
  awk '{gsub(/[\[\]<>(),|]/," ",$0);gsub(/=[^ ]*/,"",$0);for(i=1;i<=NF;i++){if($i~/^--[a-zA-Z][-a-zA-Z0-9]*$/)print $i;if($i~/^-[a-zA-Z]$/&&$i!="-")print $i}}' | sort -u
}

_fzf_complete_git() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'git {} -h 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    { git help -a 2>/dev/null | awk '/^   [a-z]/ {print $1}'; git --help 2>/dev/null | __fzf_flags; } | sort -u
  )
}
_fzf_complete_brew() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'brew help {} 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    {
      brew commands 2>/dev/null | awk '/^[a-z]/ {print $1}'
      brew --help 2>/dev/null | __fzf_flags
      printf '%s\n' --version --help --prefix --cellar --repository --caskroom --env --cache --quiet --no-auto-update
    } | sort -u
  )
}
_fzf_complete_tmux() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'tmux list-commands 2>/dev/null | grep "^{} "' \
    -- "$@" < <(
    { tmux list-commands 2>/dev/null | awk '{print $1}'; printf '%s\n' -2 -C -D -h -l -N -u -V -v -c -f -L -S -T; } | sort -u
  )
}
_fzf_complete_atuin() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'atuin {} --help 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    { atuin --help 2>/dev/null | awk '/^  [a-z]/ {print $1}'; atuin --help 2>/dev/null | __fzf_flags; } | sort -u
  )
}
_fzf_complete_dotnet() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'dotnet {} --help 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    { dotnet --help 2>/dev/null | awk '/^  [a-z]/ {print $1}'; dotnet --help 2>/dev/null | __fzf_flags; } | sort -u
  )
}
_fzf_complete_gh() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'gh {} --help 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    {
      gh --help 2>/dev/null | awk '/^  [a-z]/ && !/gh </ {gsub(/^  |:.*/,"",$0); print}'
      gh --help 2>/dev/null | __fzf_flags
    } | sort -u
  )
}
_fzf_complete_bw() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'bw {} --help 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    {
      bw --help 2>/dev/null | awk '/^Commands:/{p=1;next} p && /^  [a-z]/{print $1}'
      bw --help 2>/dev/null | __fzf_flags
    } | sort -u
  )
}
_fzf_complete_npm() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'npm {} --help 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    {
      npm help 2>/dev/null | awk '/^All commands:/{p=1;next} p && /^    [a-z]/{gsub(/,/," ",$0);for(i=1;i<=NF;i++)if($i!="")print $i}'
      printf '%s\n' --help --version
    } | sort -u
  )
}
_fzf_complete_opencode() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'opencode {} --help 2>&1 | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    {
      opencode --help 2>&1 | awk '/^  opencode / && !/\[project\]/ {print $2}'
      opencode --help 2>&1 | __fzf_flags
    } | sort -u
  )
}
_fzf_complete_fd() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'fd {} --help 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    fd --help 2>/dev/null | __fzf_flags | sort -u
  )
}
_fzf_complete_rg() {
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:70%:wrap' \
    --preview 'rg {} --help 2>/dev/null | bat -pp --color=always -l bash 2>/dev/null | head -200' \
    -- "$@" < <(
    rg --help 2>/dev/null | __fzf_flags | sort -u
  )
}

export PATH=$PATH:/Users/raphael/.spicetify

alias cat="bat"
# csc - watches clipboard, saves each copy, auto-creates .cs files when
#       filenames (ending with " X" or " x") are detected
CSC_DIR=~/.cache/csc

# Reset cursor to steady bar on every prompt (fixes block cursor after exiting nvim)
_reset_cursor() { printf '\033[6 q' >/dev/tty }
precmd_functions+=(_reset_cursor)

function cool { ~/.config/zsh/ghost }

# Composio CLI
export COMPOSIO_INSTALL_DIR="/Users/raphael/.composio"
export PATH="$COMPOSIO_INSTALL_DIR:$PATH"
export PATH="$HOME/.composio:$PATH"


# opencode
export PATH=/Users/raphael/.opencode/bin:$PATH

export OPENCODE_API_KEY="sk-10WcqcQCc3gsb3oAxZfKTNRQOa7QR1R660CZUG4lrOhqqNonhs836XuwyHkYBWSg"

export OPENCODE_PORT=4096

alias ocf='OPENCODE_CONFIG=~/.config/opencode/opencode-full.jsonc opencode '
