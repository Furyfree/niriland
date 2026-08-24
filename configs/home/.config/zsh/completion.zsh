# Completion.

zmodload zsh/complist

if [[ -d "$XDG_DATA_HOME/sheldon/repos/github.com/zsh-users/zsh-completions/src" ]]; then
  fpath+=("$XDG_DATA_HOME/sheldon/repos/github.com/zsh-users/zsh-completions/src")
fi

autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

if command -v op >/dev/null 2>&1; then
  eval "$(op completion zsh)"
fi
