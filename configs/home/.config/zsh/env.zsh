# Interactive shell options and environment.

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi
