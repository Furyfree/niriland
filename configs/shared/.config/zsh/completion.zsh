#######################################
# COMPLETION
#######################################
zmodload zsh/complist
zstyle ':completion:*' menu select

if [[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/repos/github.com/zsh-users/zsh-completions/src" ]]; then
  fpath+=("${XDG_DATA_HOME:-$HOME/.local/share}/sheldon/repos/github.com/zsh-users/zsh-completions/src")
fi

autoload -Uz compinit
compinit

if command -v op >/dev/null 2>&1; then
  eval "$(op completion zsh)"
fi
