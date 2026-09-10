#!/usr/bin/env bash

niriland_error() {
  printf 'ERROR: %s\n' "$*" >&2
}

niriland_die() {
  niriland_error "$@"
  return 1
}

niriland_trim() {
  local value="$1"

  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

niriland_validate_identifier() {
  [[ "$1" =~ ^[a-z][a-z0-9-]*$ ]]
}

niriland_state_root() {
  if [[ -n "${NIRILAND_STATE_HOME:-}" ]]; then
    printf '%s\n' "$NIRILAND_STATE_HOME"
    return
  fi

  printf '%s/niriland\n' "${XDG_STATE_HOME:-$HOME/.local/state}"
}
