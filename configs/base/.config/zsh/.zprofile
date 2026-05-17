# ~/.config/zsh/.zprofile

path=(
  "$HOME/.local/bin"
  "$HOME/.local/bin/niriland"
  "$HOME/develop/flutter/bin"
  $path
)

if [[ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]]; then
  path+=("$HOME/.local/share/JetBrains/Toolbox/scripts")
fi

typeset -U path
export PATH
