# ~/.config/zsh/.zprofile

path=(
  "$HOME/.local/bin"
  "$HOME/.local/bin/niriland"
  $path
)

typeset -U path
export PATH
