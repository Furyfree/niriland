# PATH setup for interactive shells.

path=(
  "$HOME/.local/bin"
  "$HOME/.local/bin/niriland"
  "$HOME/develop/flutter/bin"
  $path
)

typeset -U path
export PATH
