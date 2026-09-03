# Shared fzf theme (Catppuccin). Sourced by zsh keybinds.zsh and by the
# menu's pickers (menu-select, menu-pkg-*), so fzf looks the same whether
# it runs in a terminal or behind the launcher. No --bind here on purpose:
# key behavior differs per caller and stays in the callers.
export FZF_DEFAULT_OPTS=" \
--color=fg:#C6D0F5,header:#E78284,info:#CA9EE6,pointer:#F2D5CF \
--color=marker:#BABBF1,fg+:#C6D0F5,prompt:#CA9EE6,hl+:#E78284 \
--color=selected-bg:#51576D \
--color=border:#737994,label:#C6D0F5"
