# ~/.zshrc
# Modular ZSH configuration

# Configuration directory
ZSH_CONFIG_DIR="$HOME/.local/share/niriland/configs/modules/.config/zsh"

# Source configuration files in order
source "$ZSH_CONFIG_DIR/env.zsh"
source "$ZSH_CONFIG_DIR/history.zsh"
source "$ZSH_CONFIG_DIR/keybindings.zsh"
source "$ZSH_CONFIG_DIR/plugins.zsh"
source "$ZSH_CONFIG_DIR/fzf.zsh"
source "$ZSH_CONFIG_DIR/zoxide.zsh"
source "$ZSH_CONFIG_DIR/aliases.zsh"
source "$ZSH_CONFIG_DIR/functions.zsh"
source "$ZSH_CONFIG_DIR/completion.zsh"
