#######################################
# ENVIRONMENT VARIABLES
#######################################
export EDITOR=nvim

# Consolidated PATH exports
export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:$HOME/.lmstudio/bin"
export PATH="$PATH:$HOME/.dotnet/tools"
export PATH="$HOME/.local/bin/scripts:$PATH"
export PATH=$HOME/.opencode/bin:$PATH

# Starship
export STARSHIP_CONFIG=$HOME/.config/starship/starship.toml
eval "$(starship init zsh)"
