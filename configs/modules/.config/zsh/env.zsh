#######################################
# ENVIRONMENT VARIABLES
#######################################
# Mise (Environment manager for multiple languages)
eval "$(mise activate zsh)"

# Starship
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml
eval "$(starship init zsh)"
