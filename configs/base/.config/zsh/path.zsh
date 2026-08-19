# PATH setup for interactive shells.

path=(
  "$HOME/.local/bin"
  "$HOME/.local/bin/niriland"
  $path
)

typeset -U path
export PATH
