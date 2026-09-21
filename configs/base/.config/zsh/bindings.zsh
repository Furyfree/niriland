# Keybindings.

bindkey -e

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[5~' undefined-key
bindkey '^[[6~' undefined-key
bindkey '^[[3~' delete-char
bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

if [[ -n "${widgets[_fzf_file_no_hidden]:-}" ]]; then
  bindkey '^F' _fzf_file_no_hidden
fi

if [[ -n "${widgets[history-substring-search-up]:-}" ]]; then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
fi

if [[ -n "${widgets[autosuggest-toggle]:-}" ]]; then
  bindkey '^\' autosuggest-toggle
fi
