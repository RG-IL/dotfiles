ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f2d3b7"
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(buffer-empty bracketed-paste accept-line push-line-or-edit)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_COMPLETION_IGNORE="(?|*[| ]|*[| ]?)"

# Theme comes from the shared file the menu's fzf also sources; only the
# zsh-specific navigation binds live here.
source "$HOME/.config/caelestia/menu/fzf-theme.sh"
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --bind 'tab:down,btab:up'"

export FZF_COMPLETION_TRIGGER=''

zle -C native-complete complete-word _main_complete

bindkey '^I'      autosuggest-accept
bindkey '^T'      native-complete
bindkey '^['      fzf-completion
bindkey '^[[108;8u' forward-word
