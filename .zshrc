export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$HOME/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin:$PATH"
# Autoload functions on first use instead of defining at startup
fpath=(~/.config/zsh/functions $fpath)

# Generated native zsh completions (replaces fzf-based atuin completions)
if [[ ! -f ~/.config/zsh/functions/_atuin ]] && [[ -x /usr/bin/atuin ]]; then
  /usr/bin/atuin gen-completions --shell zsh --out-dir ~/.config/zsh/functions
fi

autoload -Uz ai iv ls y _atuin_ai_from_buffer
autoload -Uz compinit && compinit -C -d ~/.cache/zsh/completion.dump

[[ -d ~/.cache/zsh ]] || mkdir -p ~/.cache/zsh
setopt SHARE_HISTORY



if [[ ! -f ~/.cache/zsh/omp-init.zsh || ~/.ZSHThemes.json -nt ~/.cache/zsh/omp-init.zsh ]]; then
  oh-my-posh init zsh --config ~/.ZSHThemes.json > ~/.cache/zsh/omp-init.zsh
fi
source ~/.cache/zsh/omp-init.zsh

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f2d3b7"

[ -f ~/.cache/zsh/fzf-init.zsh ] || fzf --zsh > ~/.cache/zsh/fzf-init.zsh
source ~/.cache/zsh/fzf-init.zsh

# Override fzf-completion to use generic completions for all commands
fzf-completion() {
  local tokens prefix trigger tail matches lbuf d_cmds cursor_pos cmd_word
  setopt localoptions noshwordsplit noksh_arrays noposixbuiltins

  tokens=(${(z)LBUFFER})
  if [ ${#tokens} -lt 1 ]; then
    zle ${fzf_default_completion:-expand-or-complete}
    return
  fi

  trigger=${FZF_COMPLETION_TRIGGER-'**'}
  [[ -z $trigger && ${LBUFFER[-1]} == ' ' ]] && tokens+=("")

  if [[ ${LBUFFER} = *"${tokens[-2]-}${tokens[-1]}" ]]; then
    tokens[-2]="${tokens[-2]-}${tokens[-1]}"
    tokens=(${tokens[0,-2]})
  fi

  lbuf=$LBUFFER
  tail=${LBUFFER:$(( ${#LBUFFER} - ${#trigger} ))}

  if [ ${#tokens} -gt 1 -a "$tail" = "$trigger" ]; then
    d_cmds=(${=FZF_COMPLETION_DIR_COMMANDS-cd pushd rmdir})

    {
      cursor_pos=$CURSOR
      CURSOR=$((cursor_pos - ${#trigger} - 1))
      if ! zmodload -F zsh/parameter p:functions 2>/dev/null || ! (( ${+functions[compdef]} )); then
        zmodload -F zsh/compctl 2>/dev/null
      fi
      zle -C __fzf_extract_command .complete-word __fzf_extract_command
      zle __fzf_extract_command
    } always {
      CURSOR=$cursor_pos
      zle -D __fzf_extract_command  2>/dev/null
    }

    [ -z "$trigger"      ] && prefix=${tokens[-1]} || prefix=${tokens[-1]:0:-${#trigger}}
    if [[ $prefix = *'$('* ]] || [[ $prefix = *'<('* ]] || [[ $prefix = *'>('* ]] || [[ $prefix = *':='* ]] || [[ $prefix = *'`'* ]]; then
      return
    fi
    [ -n "${tokens[-1]}" ] && lbuf=${lbuf:0:-${#tokens[-1]}}

    if eval "noglob type _fzf_complete_${cmd_word} >/dev/null"; then
      prefix="$prefix" eval _fzf_complete_${cmd_word} ${(q)lbuf}
      zle reset-prompt
    elif [ ${d_cmds[(i)$cmd_word]} -le ${#d_cmds} ]; then
      _fzf_dir_completion "$prefix" "$lbuf"
    elif [[ "$cmd_word" == (nvim|vim|vi|nano|emacs|less) ]]; then
      _fzf_path_completion "$prefix" "$lbuf"
    elif [[ -n "${_comps[$cmd_word]-}" ]] || (( ${+functions[_$cmd_word]} )); then
      _fzf_complete --height=40% --layout=reverse --prompt=" > " \
        --preview-window 'right:50%:wrap' \
        --preview "grep -m1 '^{}:' ${TMPDIR:-/tmp}/fzf-desc-${cmd_word}-* 2>/dev/null | cut -d: -f2-" \
        -- "$lbuf" < <(__fzf_generic_completions "$cmd_word" "$lbuf")
      command rm -f ${TMPDIR:-/tmp}/fzf-desc-${cmd_word}-*
      zle reset-prompt
    else
      _fzf_path_completion "$prefix" "$lbuf"
    fi
  else
    zle ${fzf_default_completion:-expand-or-complete}
  fi
}

bindkey '^I'      autosuggest-accept

# Override fzf dir completion to show hidden directories
_fzf_compgen_dir() {
  command fd --type d --follow --hidden \
    --exclude '.git' --exclude 'target' --exclude 'node_modules' \
    --exclude '.cache' --exclude 'Library' --exclude 'vendor' \
    --exclude '.cargo' --exclude '.venv' --exclude '.direnv' \
    --exclude '.vscode' --exclude '.dotnet' --exclude '.wine' \
    --exclude '.agents' --exclude '.terraform' --exclude '.github' \
    --exclude '.gem' --exclude '.ServiceHub' \
    --exclude '.atuin' --exclude '.copilot' --exclude '.zsh_sessions' \
    --exclude '.hg' --exclude '.svn' \
    --exclude '.aspnet' --exclude '.npm' \
    --exclude '.trash' --exclude '.rustup' \
    --exclude '.homebrew' --exclude '.zcompcache' --exclude '.nuget' \
    --exclude '.omo' --exclude '.Trash' \
    --exclude '.local' --exclude '.config/raycast-x' --exclude '.config/raycast' \
    --exclude '.agi' --exclude '.android' --exclude '.bash_sessions' \
    . "$1" 2>/dev/null | sed 's@^\./@@'
}

# Generic fzf completion: subcommands + flags from compdef files or --help
__fzf_generic_completions() {
  local cmd="$1"
  local lbuf="$2"
  local lookup="${TMPDIR:-/tmp}/fzf-desc-${cmd}-$$"

  # Parse subcommands from lbuf (non-flag words after the command)
  local words=(${(z)lbuf})
  local -a subcmds=()
  for w in $words[2,-1]; do
    [[ -z $w || $w == -* ]] && continue
    subcmds+=("$w")
  done

  # Find the completion file for this command in fpath
  local compfile=""
  for p in $fpath; do
    if [[ -f "$p/_$cmd" ]]; then
      compfile="$p/_$cmd"
      break
    fi
  done

  {
    if [[ ${#subcmds} -eq 0 ]]; then
      # Top-level: subcommands from compdef file
      if [[ -n "$compfile" ]]; then
        grep -E "^\s+[a-z][-a-z]+:'[^']+'" "$compfile" 2>/dev/null \
          | sed "s/^[[:space:]]*//;s/'//g;s/)$//" | cut -d: -f1
        # Top-level flags
        grep -oE "(-?-[-a-zA-Z0-9=]+)\[[^]]*\]" "$compfile" 2>/dev/null \
          | sed "s/\[/:/;s/\]$//"
        grep -oE "\{-.,--[-a-zA-Z0-9=]+\}'\[[^]]*\]" "$compfile" 2>/dev/null \
          | sed "s/{-.,//;s/}'\[/:/;s/\]$//"
      fi
      # Always supplement with --help
      $cmd --help 2>/dev/null | __fzf_flags
      $cmd --help 2>/dev/null | awk '
        /^[[:space:]]+[a-z][a-z0-9_-]+[[:space:]]/ && !/^[[:space:]]+--/ {
          gsub(/^[[:space:]]+/, ""); sub(/[: ].*/, ""); print
        }
      '
    else
      # Subcommand level: try _cmd-subcmd function in compdef
      if [[ -n "$compfile" ]]; then
        # Try _cmd-subcmd function
        local funcbody
        funcbody=$(sed -n "/^_${cmd}-${subcmds[1]}[() ]/,/^(( /p" "$compfile" 2>/dev/null)

        if [[ -n "$funcbody" ]]; then
          if [[ ${#subcmds} -ge 2 ]]; then
            # Sub-subcommand: look for flags in case branch
            echo "$funcbody" | sed -n "/(\{0,1\}${subcmds[2]})/,/;;\|esac/p" \
              | grep -oE "'--?[-a-zA-Z=]+\[[^]]*\]" \
              | sed "s/^'//;s/\[/:/;s/\]$//"
          else
            # Check for sub-subcommands
            local sub_commands
            sub_commands=$(echo "$funcbody" | grep -E "^\s+[-a-z]+:'[^']+'" \
              | sed "s/^[[:space:]]*//;s/'//g;s/)$//")
            if [[ -n $sub_commands ]]; then
              echo "$sub_commands"
            else
              # Show flags from the subcommand function
              echo "$funcbody" \
                | grep -oE "'--?[-a-zA-Z=]+\[[^]]*\]" \
                | sed "s/^'//;s/\[/:/;s/\]$//"
            fi
          fi
        fi
      fi
      # Supplement with cmd subcmd --help
      $cmd "${subcmds[@]}" --help 2>/dev/null | __fzf_flags
      $cmd "${subcmds[@]}" --help 2>/dev/null | awk '
        /^[[:space:]]+[a-z][a-z0-9_-]+[[:space:]]/ && !/^[[:space:]]+--/ {
          gsub(/^[[:space:]]+/, ""); sub(/[: ].*/, ""); print
        }
      '
    fi
  } 2>/dev/null | sort -u | tee "$lookup" | cut -d: -f1

}
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(buffer-empty bracketed-paste accept-line push-line-or-edit)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export FZF_COMPLETION_TRIGGER=''
zle -C native-complete complete-word _main_complete
bindkey '^T' native-complete
LISTMAX=0
bindkey '^[' fzf-completion
bindkey '^[[108;8u' forward-word

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# Insert mode = bar, Normal mode = block (vim-like)

alias cd="z"
alias n="nvim"
if [[ ! -f ~/.cache/zsh/zx-init.zsh ]]; then
  zoxide init zsh > ~/.cache/zsh/zx-init.zsh
fi
source ~/.cache/zsh/zx-init.zsh
alias oc='opencode'



# Defer slow plugins to first prompt
typeset -a _zsh_defer_plugins
_zsh_defer_plugins=(
  "$HOME/.cache/zsh/at-init.zsh"
  "$HOME/.local/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
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
  local lookup="${TMPDIR:-/tmp}/git-desc-$$"
  local gitcomp="/usr/share/zsh/functions/Completion/Unix/_git"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <(
    local words=(${(z)@})
    # Collect non-flag arguments after 'git'
    local -a subcmds=()
    for w in $words[2,-1]; do
      [[ -z $w || $w == -* ]] && continue
      subcmds+=("$w")
    done
    {
      if [[ ${#subcmds} -eq 0 ]]; then
        # Top-level: all git commands
        grep -E "^\s+[a-z][-a-z]+:'[^']+'" "$gitcomp" 2>/dev/null \
          | sed "s/^[[:space:]]*//;s/'//g;s/)$//" | tee "$lookup" | cut -d: -f1
      else
        # Extract the _git-<subcmd> function body
        local funcbody
        funcbody=$(sed -n "/^_git-${subcmds[1]}[() ]/,/^(( /p" "$gitcomp" 2>/dev/null)

        if [[ ${#subcmds} -ge 2 ]]; then
          # Sub-subcommand: look for flags in the case branch for subcmds[2]
          echo "$funcbody" | sed -n "/(\{0,1\}${subcmds[2]})/,/;;\|esac/p" \
            | grep -oE "'--?[-a-zA-Z=]+\[[^]]*\]" \
            | sed "s/^'//;s/\[/:/;s/\]$//" | tee "$lookup" | cut -d: -f1
        else
          # Check if this subcommand has sub-subcommands defined
          local sub_commands
          sub_commands=$(echo "$funcbody" | grep -E "^\s+[-a-z]+:'[^']+'" \
            | sed "s/^[[:space:]]*//;s/'//g;s/)$//")

          if [[ -n $sub_commands ]]; then
            # Show sub-subcommands (e.g., maintenance → run, start, stop)
            echo "$sub_commands" | tee "$lookup" | cut -d: -f1
          else
            # No sub-subcommands, show flags
            echo "$funcbody" \
              | grep -oE "'--?[-a-zA-Z=]+\[[^]]*\]" \
              | sed "s/^'//;s/\[/:/;s/\]$//" | tee "$lookup" | cut -d: -f1
          fi
        fi
      fi
    } | sort -u
  )
  command rm -f "$lookup"
}

_fzf_complete_brew() {
      local lookup="${TMPDIR:-/tmp}/brew-desc-$$"
      local brewcomp="/opt/homebrew/completions/zsh/_brew"
      _fzf_complete --height=40% --layout=reverse --prompt=" > " \
        --preview-window 'right:50%:wrap' \
        --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
        -- "$@" < <(
        local words=(${(z)@})
        local -a subcmds=()
        for w in $words[2,-1]; do
          [[ -z $w || $w == -* ]] && continue
          subcmds+=("$w")
        done
        {
          if [[ ${#subcmds} -eq 0 ]]; then
            # Top-level commands from commands=() array
            sed -n "/^  commands=(/,/^  )/p" "$brewcomp" 2>/dev/null \
              | grep -E "^\s+'" | sed "s/^[[:space:]]*'//;s/'$//"
            # Top-level flags
            sed -n "/^_brew()/,/^}/p" "$brewcomp" 2>/dev/null \
              | grep -oE "(-?-[-a-zA-Z=]+)\[[^]]*\]" \
              | sed "s/\[/:/;s/\]$//"
          elif [[ ${#subcmds} -eq 1 ]]; then
            # Get the function body for _brew_<subcmd>
            local funcname="_brew_${subcmds[1]//-/_}"
            local funcbody
            funcbody=$(sed -n "/^${funcname}()/,/^}/p" "$brewcomp" 2>/dev/null)
            # Sub-subcommands
            echo "$funcbody" | grep -E "^\s+'[a-z][-a-z]*:" \
              | sed "s/^[[:space:]]*'//;s/'$//"
            # Flags
            echo "$funcbody" \
              | grep -oE "(-?-[-a-zA-Z=]+)\[[^]]*\]" \
              | sed "s/\[/:/;s/\]$//"
          else
            # Sub-subcommand: look for case branch in _brew_<subcmd>
            local funcname="_brew_${subcmds[1]//-/_}"
            local funcbody
            funcbody=$(sed -n "/^${funcname}()/,/^}/p" "$brewcomp" 2>/dev/null)
            echo "$funcbody" | sed -n "/${subcmds[2]})/,/;;\|esac/p" \
              | grep -oE "(-?-[-a-zA-Z=]+)\[[^]]*\]" \
              | sed "s/\[/:/;s/\]$//"
          fi
        } | sort -u | tee "$lookup" | cut -d: -f1
      )
      command rm -f "$lookup"
    }

_fzf_complete_tmux() {
  local lookup="${TMPDIR:-/tmp}/tmux-desc-$$"
  local tmuxcomp="/usr/share/zsh/functions/Completion/Unix/_tmux"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <(
    local words=(${(z)@})
    # Collect non-flag arguments after 'tmux'
    local -a subcmds=()
    for w in $words[2,-1]; do
      [[ -z $w || $w == -* ]] && continue
      subcmds+=("$w")
    done
    {
      if [[ ${#subcmds} -eq 0 ]]; then
        # Top-level: all tmux commands with descriptions
        grep "^_tmux-" "$tmuxcomp" | sed 's/() {//' | while read -r func; do
          local cmd="${func#_tmux-}"
          local desc=$(sed -n "/^${func}()/,/return$/p" "$tmuxcomp" | grep 'print "' | head -1 | sed 's/.*print "//;s/".*//')
          [[ -n $desc ]] && echo "${cmd}:${desc}" || echo "$cmd"
        done | tee "$lookup" | cut -d: -f1
        # Top-level flags (-l, -L, -S, etc.) from _tmux() function
        sed -n "/^_tmux()/,/^}/p" "$tmuxcomp" 2>/dev/null \
          | grep -oE "(-?-[-a-zA-Z=]+)[+=]*\[[^]]*\]" \
          | sed "s/[+=]*\[/:/;s/\]$//" | tee -a "$lookup" | cut -d: -f1
      else
        # Subcommand: extract flags from _tmux-<subcmd> function
        sed -n "/^_tmux-${subcmds[1]}()/,/^}/p" "$tmuxcomp" 2>/dev/null \
          | grep -oE "(-?-[-a-zA-Z=]+)[+=]*\[[^]]*\]" \
          | sed "s/[+=]*\[/:/;s/\]$//" | tee "$lookup" | cut -d: -f1
      fi
    } | sort -u
  )
  command rm -f "$lookup"
}

_fzf_complete_atuin() {
  local lookup="${TMPDIR:-/tmp}/atuin-desc-$$"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <(
    local words=(${(z)@}) fun="_atuin_commands"
    for w in $words[2,-1]; do
      [[ -z $w ]] && continue
      fun="${fun%_commands}__${w}_commands"
    done
    {
      sed -n "/^${fun}()/,/^}/p" ~/.config/zsh/functions/_atuin 2>/dev/null | grep "^'" | cut -d"'" -f2 > "$lookup"
      sed -n "/^${fun}()/,/^}/p" ~/.config/zsh/functions/_atuin 2>/dev/null | grep "^'" | cut -d"'" -f2 | cut -d: -f1
      [[ $words[2] == "" ]] && atuin --help 2>/dev/null | __fzf_flags
    } | sort -u
  )
  command rm -f "$lookup"
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

_fzf_complete_npm() {
      local lookup="${TMPDIR:-/tmp}/npm-desc-$$"
      _fzf_complete --height=40% --layout=reverse --prompt=" > " \
        --preview-window 'right:50%:wrap' \
        --preview "npm {} -h 2>/dev/null | head -5" \
        -- "$@" < <(
        local words=(${(z)@})
        local -a subcmds=()
        for w in $words[2,-1]; do
          [[ -z $w || $w == -* ]] && continue
          subcmds+=("$w")
        done
        {
          if [[ ${#subcmds} -eq 0 ]]; then
            COMP_CWORD=1 COMP_LINE="npm " COMP_POINT=4 \
              npm completion -- "npm" "" 2>/dev/null
            COMP_CWORD=1 COMP_LINE="npm -" COMP_POINT=5 \
              npm completion -- "npm" "-" 2>/dev/null
            echo "--version"
            echo "--help"
            echo "-v"
            echo "-h"
          else
            npm "${subcmds[1]}" -h 2>/dev/null | awk '
              /^  -[A-Za-z]\|--[-a-z]/ {
                split($0, a, "|")
                short = a[1]; gsub(/^  /, "", short)
                long = a[2]; sub(/ .*/, "", long)
                flag = short "|" long
                getline; gsub(/^  +/, "")
                printf "%s:%s\n", flag, $0
              }
              /^  --[-a-z]/ {
                flag = $1
                getline; gsub(/^  +/, "")
                printf "%s:%s\n", flag, $0
              }
            ' > "$lookup"
            cut -d: -f1 "$lookup"
          fi
        } | sort -u
      )
      command rm -f "$lookup"
    }



_fzf_complete_opencode() {
  local lookup="${TMPDIR:-/tmp}/opencode-desc-$$"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <(
    local words=(${(z)@})
    local nwords=${#words}
    {
      # Get subcommands/values
      COMP_CWORD="$((nwords-1))" COMP_LINE="${words[*]}" COMP_POINT="${#${words[*]}}" \
        opencode --get-yargs-completions "${words[@]}" "" 2>/dev/null
      # Get flags
      COMP_CWORD="$((nwords-1))" COMP_LINE="${words[*]} -" COMP_POINT="$((${#${words[*]}}+2))" \
        opencode --get-yargs-completions "${words[@]}" "-" 2>/dev/null
    } | sort -u | tee "$lookup" | cut -d: -f1
  )
  command rm -f "$lookup"
}
_fzf_complete_oc(){
    _fzf_complete_opencode "$@"
}
_fzf_complete_ocf(){
    _fzf_complete_opencode "$@"
}

_fzf_complete_fd() {
  local lookup="${TMPDIR:-/tmp}/fd-desc-$$"
  local fdcomp="/usr/share/zsh/site-functions/_fd"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <(
    {
      # Match '--flag[desc]' format
      grep -oE "(-?-[-a-zA-Z0-9=]+)\[[^]]*\]" "$fdcomp" 2>/dev/null \
        | sed "s/\[/:/;s/\]$//"
      # Match '{-X,--flag}'[desc]' format
      grep -oE "\{-.,--[-a-zA-Z0-9=]+\}'\[[^]]*\]" "$fdcomp" 2>/dev/null \
        | sed "s/{-.,//;s/}'\[/:/;s/\]$//"
    } | sort -u | tee "$lookup" | cut -d: -f1
  )
  command rm -f "$lookup"
}

_fzf_complete_rg() {
  local lookup="${TMPDIR:-/tmp}/rg-desc-$$"
  local rgcomp="/usr/share/zsh/site-functions/_rg"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <(
    {
      grep -oE "(-?-[-a-zA-Z0-9=]+)\[[^]]*\]" "$rgcomp" 2>/dev/null \
        | sed "s/\[/:/;s/\]$//" | tee "$lookup" | cut -d: -f1
    } | sort -u
  )
  command rm -f "$lookup"
}

_fzf_complete_bat() {
  local lookup="${TMPDIR:-/tmp}/bat-desc-$$"
  local batcomp="/usr/share/zsh/site-functions/_bat"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <({
    sed -n "s/.*\(--[-a-zA-Z0-9=]*\)[^[]*\[\([^]]*\)\].*/\1:\2/p" "$batcomp" 2>/dev/null
  } | sort -u | tee "$lookup" | cut -d: -f1)
  command rm -f "$lookup"
}

_fzf_complete_delta() {
  local lookup="${TMPDIR:-/tmp}/delta-desc-$$"
  local deltacomp="/opt/homebrew/share/zsh/site-functions/_delta"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <({
    sed -n "s/.*\(--[-a-zA-Z0-9=]*\)[^[]*\[\([^]]*\)\].*/\1:\2/p" "$deltacomp" 2>/dev/null
  } | sort -u | tee "$lookup" | cut -d: -f1)
  command rm -f "$lookup"
}

_fzf_complete_eza() {
  local lookup="${TMPDIR:-/tmp}/eza-desc-$$"
  local ezacomp="/usr/share/zsh/site-functions/_eza"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <({
    sed -n "s/.*\(--[-a-zA-Z0-9=]*\)[^[]*\[\([^]]*\)\].*/\1:\2/p" "$ezacomp" 2>/dev/null
  } | sort -u | tee "$lookup" | cut -d: -f1)
  command rm -f "$lookup"
}

_fzf_complete_mpv() {
  local lookup="${TMPDIR:-/tmp}/mpv-desc-$$"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <({
    mpv --no-config --list-options 2>/dev/null \
      | awk '{for(i=1;i<=NF;i++) if($i~/^--/) print $i}'
  } | sort -u | tee "$lookup" | cut -d: -f1)
  command rm -f "$lookup"
}

_fzf_complete_yazi() {
  local lookup="${TMPDIR:-/tmp}/yazi-desc-$$"
  local yazicomp="/usr/share/zsh/site-functions/_yazi"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <({
    sed -n "s/.*\(--[-a-zA-Z0-9=]*\)[^[]*\[\([^]]*\)\].*/\1:\2/p" "$yazicomp" 2>/dev/null
  } | sort -u | tee "$lookup" | cut -d: -f1)
  command rm -f "$lookup"
}

_fzf_complete_yt-dlp() {
  local lookup="${TMPDIR:-/tmp}/yt-dlp-desc-$$"
  _fzf_complete --height=40% --layout=reverse --prompt=" > " \
    --preview-window 'right:50%:wrap' \
    --preview "grep -m1 '^{}:' $lookup 2>/dev/null | cut -d: -f2-" \
    -- "$@" < <({
    yt-dlp --help 2>/dev/null | grep -oE '\s--[-a-zA-Z-]+' | sed 's/^ *//'
  } | sort -u | tee "$lookup" | cut -d: -f1)
  command rm -f "$lookup"
}


alias cat="bat"
# Reset cursor to steady bar on every prompt (fixes block cursor after exiting nvim)
_reset_cursor() { printf '\033[6 q' >/dev/tty }
precmd_functions+=(_reset_cursor)

# opencode
export PATH=/Users/raphael/.opencode/bin:$PATH || export PATH=/home/Raphael/.opencode/bin:$PATH

export OPENCODE_PORT=4096

alias ocf='OPENCODE_CONFIG=~/.config/opencode/opencode-full.jsonc opencode '
ZSH_AUTOSUGGEST_COMPLETION_IGNORE="(?|*[| ]|*[| ]?)"

music() {
    termusic --layout-4
}
export PATH="/home/Raphael/.local/bin:$PATH"



