#######################################
# SHELDON (PLUGIN MANAGER)
#######################################
export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR/completions"

eval "$(sheldon source)"

#######################################
# 1PASSWORD CLI INTEGRATION
#######################################
if [[ -f "$HOME/.op/plugins.sh" ]]; then
  source "$HOME/.op/plugins.sh"
elif [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh" ]]; then
  source "${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh"
fi
