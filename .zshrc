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
anifetch --framerate 30 --playback-rate 30 -ca '--symbols brail --fg-only' -w 90 -H 20  /Users/raphael/.config/fastfetch/ghostty-ani.mov

coddy(){
  python3 /Users/raphael/.config/random-scripts/screen_section_scraper.py
}

export PATH="/Library/Frameworks/Python.framework/Versions/3.14/bin:$PATH"
export BREW_PREFIX="$(brew --prefix)"
[[ -d ~/.cache/zsh ]] || mkdir -p ~/.cache/zsh
setopt SHARE_HISTORY
rs() {
    local port="${1:-4444}"
    local cmd="/Users/raphael/JumpGame/penelope-0.19.1/penelope.py"
    local py="/opt/homebrew/bin/python3.11"

    local pids names

    cleanup() {

        pids=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null)

        if [ -n "$pids" ]; then
            names=$(echo "$pids" | xargs -I {} ps -p {} -o comm= 2>/dev/null | xargs -I {} basename "{}")
            echo -e "\033[1;31m[!] Killing listener: $names\033[0m"

            kill -TERM $pids 2>/dev/null

            pids=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null)
            if [ -n "$pids" ]; then
                names=$(echo "$pids" | xargs -I {} ps -p {} -o comm= 2>/dev/null | xargs -I {} basename "{}")
                echo -e "\033[1;31m[!] Force killing: $names\033[0m"
                kill -9 $pids 2>/dev/null
            fi
        else
            echo -e "\033[1;32m[✓] Port $port is free\033[0m"
        fi

        sleep 0.05
    }

    trap cleanup EXIT INT TERM QUIT

    pids=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null)
    if [ -n "$pids" ]; then
        echo -e "\033[1;31m[-] Port $port עדיין תפוס אחרי cleanup\033[0m"
        return 1
    fi

    echo -e "\033[1;33m[+] Starting Penelope on port $port...\033[0m"
    "$py" "$cmd" -p "$port"
}


רד() {
    local port="${1:-4444}"
    local cmd="/Users/raphael/JumpGame/penelope-0.19.1/penelope.py"
    local py="/opt/homebrew/bin/python3.11"

    local pids names

    cleanup() {

        pids=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null)

        if [ -n "$pids" ]; then
            names=$(echo "$pids" | xargs -I {} ps -p {} -o comm= 2>/dev/null | xargs -I {} basename "{}")
            echo -e "\033[1;31m[!] Killing listener: $names\033[0m"

            kill -TERM $pids 2>/dev/null

            pids=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null)
            if [ -n "$pids" ]; then
                names=$(echo "$pids" | xargs -I {} ps -p {} -o comm= 2>/dev/null | xargs -I {} basename "{}")
                echo -e "\033[1;31m[!] Force killing: $names\033[0m"
                kill -9 $pids 2>/dev/null
            fi
        else
            echo -e "\033[1;32m[✓] Port $port is free\033[0m"
        fi

        sleep 0.05
    }

    trap cleanup EXIT INT TERM QUIT

    pids=$(lsof -ti tcp:"$port" -sTCP:LISTEN 2>/dev/null)
    if [ -n "$pids" ]; then
        echo -e "\033[1;31m[-] Port $port עדיין תפוס אחרי cleanup\033[0m"
        return 1
    fi

    echo -e "\033[1;33m[+] Starting Penelope on port $port...\033[0m"
    "$py" "$cmd" -p "$port"
}



ai() {
    opencode run "$1"
}

if [[ ! -f ~/.cache/zsh/omp-init.zsh || ~/.ZSHThemes.json -nt ~/.cache/zsh/omp-init.zsh ]]; then
  oh-my-posh init zsh --config ~/.ZSHThemes.json > ~/.cache/zsh/omp-init.zsh
fi
source ~/.cache/zsh/omp-init.zsh

export TERM=xterm-256color

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f2d3b7"
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

bindkey '^I'      autosuggest-accept
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(buffer-empty bracketed-paste accept-line push-line-or-edit)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true
export FZF_COMPLETION_TRIGGER=''
bindkey '^[' fzf-completion
bindkey '^[^L' forward-word
# Insert mode = bar, Normal mode = block (vim-like)

function ls() {
    local show_all=0
    for arg in "$@"; do
        if [[ "$arg" == -*a* ]]; then
            show_all=1
            break
        fi
    done

    local eza_args=(
        --long
        --color=always
        --icons
        --no-filesize
        --no-time
        --no-user
        --no-permissions
        --group-directories-first
    )

    if [[ $show_all -eq 1 ]]; then
        eza "${eza_args[@]}" -A "$@"
    else
        local mac_hidden=$(command ls -lO | grep 'hidden' | awk '{print $NF}' | tr '\n' '|')
        mac_hidden=${mac_hidden%|}

        if [[ -n "$mac_hidden" ]]; then
            eza "${eza_args[@]}" --ignore-glob="$mac_hidden" "$@"
        else
            eza "${eza_args[@]}" "$@"
        fi
    fi
}
alias cd="z"
if [[ ! -f ~/.cache/zsh/zx-init.zsh ]]; then
  zoxide init zsh > ~/.cache/zsh/zx-init.zsh
fi
source ~/.cache/zsh/zx-init.zsh
iv() {
  fd --type f --hidden --follow \
    --exclude Library \
    --exclude .git \
    --exclude .cache \
    --exclude .local \
    --exclude .ssh \
    --exclude .vscode \
    --exclude .npm \
    --exclude .rustup \
    --exclude .dotnet \
    --exclude .wine \
    --exclude .zsh_sessions \
    --exclude .zsh_history \
    --exclude .bash_sessions \
    --exclude .ServiceHub \
    --exclude .codex \
    --exclude .android \
    --exclude .Trash \
    --exclude x.app \
    --exclude Movies \
    --exclude Music \
    --exclude Pictures \
    --exclude .nuget \
    --exclude pygame \
    --exclude Frameworks \
    --exclude python3.14 \
    --exclude Applications \
    --exclude .ruff_cache \
  | fzf -m --preview 'bat --color=always {}' \
  | xargs -o nvim
}

ןה() {
  fd --type f --hidden --follow \
    --exclude Library \
    --exclude .git \
    --exclude .cache \
    --exclude .local \
    --exclude .ssh \
    --exclude .vscode \
    --exclude .npm \
    --exclude .rustup \
    --exclude .dotnet \
    --exclude .wine \
    --exclude .zsh_sessions \
    --exclude .zsh_history \
    --exclude .bash_sessions \
    --exclude .ServiceHub \
    --exclude .codex \
    --exclude .android \
    --exclude .Trash \
    --exclude x.app \
    --exclude Movies \
    --exclude Music \
    --exclude Pictures \
    --exclude .nuget \
    --exclude pygame \
    --exclude Frameworks \
    --exclude python3.14 \
    --exclude Applications \
    --exclude .ruff_cache \
  | fzf -m --preview 'bat --color=always {}' \
  | xargs -o nvim
}


alias oc="opencode"



source $BREW_PREFIX/opt/zsh-fast-syntax-highlighting/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"
function y() {
	local tmp cwd target

	tmp="$(mktemp -t yazi-cwd.XXXXXX)"

	if [[ -n "$1" ]]; then
		if [[ -d "$1" ]]; then
			target="$1"
		else
			target="$(zoxide query -- "$1" 2>/dev/null)"

			if [[ -z "$target" ]]; then
				echo "zoxide: no match found for '$1'"
				rm -f -- "$tmp"
				return 1
			fi
		fi
	fi

	if [[ -n "$target" ]]; then
		command yazi "$target" --cwd-file="$tmp"
	else
		command yazi --cwd-file="$tmp"
	fi

	if [[ -f "$tmp" ]]; then
		cwd="$(cat "$tmp")"

		if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
			cd "$cwd"
		fi
	fi

	rm -f -- "$tmp"
}


export EDITOR="nvim"
export VISUAL="nvim"

. "$HOME/.atuin/bin/env"

if [[ ! -f ~/.cache/zsh/at-init.zsh ]]; then
  atuin init zsh > ~/.cache/zsh/at-init.zsh
fi
source ~/.cache/zsh/at-init.zsh

# play Spotify liked songs (starts hidden, no window)
spl() {
  (
    osascript -e '
      tell application "Spotify" to launch
      delay 0.5
      tell application "Spotify" to play track "spotify:collection:tracks"
    ' 2>/dev/null
    sleep 1
    osascript -e '
      tell application "System Events"
        set visible of process "Spotify" to false
      end tell
    ' 2>/dev/null
  ) &>/dev/null &!
}

# Atuin AI: type a prompt, then hit Ctrl+O to send it to AI
_atuin_ai_from_buffer() {
    local query="$BUFFER"
    BUFFER=""
    local output
    output=$(atuin ai inline "$query" 3>&1 1>&2 2>&3)

    if [[ $output == __atuin_ai_execute__:* ]]; then
        LBUFFER=${output#__atuin_ai_execute__:}
        RBUFFER=""
        zle reset-prompt
        zle accept-line
    elif [[ $output == __atuin_ai_insert__:* ]]; then
        LBUFFER=${output#__atuin_ai_insert__:}
        RBUFFER=""
        zle reset-prompt
    elif [[ $output == __atuin_ai_cancel__ ]]; then
        zle reset-prompt
    elif [[ $output == __atuin_ai_print__:* ]]; then
        zle -I
        echo "${output#__atuin_ai_print__:}"
    elif [[ -n $output ]]; then
        LBUFFER=$output
        RBUFFER=""
        zle reset-prompt
    else
        zle reset-prompt
    fi
}
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
function csc() {
  mkdir -p $CSC_DIR && rm -f $CSC_DIR/[0-9]*.txt(N)
  local last="$(pbpaste)" n=0
  echo "csc: copy code blocks, then filenames ending with X"
  echo "     (Ctrl+C to cancel)"
  while true; do
    sleep 0.3
    local clip="$(pbpaste 2>/dev/null)"
    [[ -n "$clip" && "$clip" != "$last" ]] || continue
    printf -v pad "%03d" $n
    echo "$clip" > "$CSC_DIR/$pad.txt"
    echo "  saved #$pad: ${clip:0:50}"
    last="$clip"; n=$((n + 1))
    local all_fname=1
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      [[ "$line" == *" X" || "$line" == *" x" ]] || { all_fname=0; break; }
    done <<< "$clip"
    if (( all_fname )); then echo "detected filenames → creating files..."; break; fi
  done
  local -a files=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local f="${line% X}"; [[ "$f" == "$line" ]] && f="${line% x}"
    files+=("$f")
  done <<< "$clip"
  (( ${#files} > 0 )) || { echo "no filenames found"; return 1; }
  local entries=($CSC_DIR/[0-9]*.txt(N))
  local content_n=$(( ${#entries} - 1 ))
  rm -f *.cs(N)
  for f in $files; do : > "$f"; done
  local i=1
  for f in $files; do
    (( i <= content_n )) && cp "${entries[$i]}" "$f"
    (( i++ ))
  done
  rm -rf $CSC_DIR
  nvim -- $files
}

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
alias cool="anifetch --framerate 30 --playback-rate 30 -ca '--symbols brail --fg-only' -w 90 -H 20  /Users/raphael/.config/fastfetch/ghostty-ani.mov"
