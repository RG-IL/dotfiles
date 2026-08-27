ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f2d3b7"
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(buffer-empty bracketed-paste accept-line push-line-or-edit)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=true
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_COMPLETION_IGNORE="(?|*[| ]|*[| ]?)"

export FZF_DEFAULT_OPTS=" \
--color=fg:#C6D0F5,header:#E78284,info:#CA9EE6,pointer:#F2D5CF \
--color=marker:#BABBF1,fg+:#C6D0F5,prompt:#CA9EE6,hl+:#E78284 \
--color=selected-bg:#51576D \
--color=border:#737994,label:#C6D0F5 \
--bind 'tab:down,btab:up'"

export FZF_COMPLETION_TRIGGER=''

zle -C native-complete complete-word _main_complete

bindkey '^I'      autosuggest-accept
bindkey '^T'      native-complete
bindkey '^['      fzf-completion
bindkey '^[[108;8u' forward-word
