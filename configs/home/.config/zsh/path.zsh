# PATH setup for interactive shells.

path=(
  "$HOME/.local/bin"
  $path
)

typeset -U path
export PATH
