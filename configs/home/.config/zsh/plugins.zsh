# Sheldon plugin manager.

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"

if command -v sheldon >/dev/null 2>&1; then
  eval "$(sheldon source)"
fi

if [[ -f "$HOME/.op/plugins.sh" ]]; then
  source "$HOME/.op/plugins.sh"
elif [[ -f "$XDG_CONFIG_HOME/op/plugins.sh" ]]; then
  source "$XDG_CONFIG_HOME/op/plugins.sh"
fi
