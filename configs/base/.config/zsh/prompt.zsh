# Prompt.

export VIRTUAL_ENV_DISABLE_PROMPT=1

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
