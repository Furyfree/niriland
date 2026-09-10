#!/usr/bin/env bash

# shellcheck source=src/niriland/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

declare -g NIRILAND_SUDO_KEEPALIVE_PID=""
declare -g NIRILAND_SUDO_KEEPALIVE_FD=""
declare -g NIRILAND_SUDO_INVALIDATE_ON_STOP=false

niriland_sudo_session_close_signal_fd() {
  if [[ -n "$NIRILAND_SUDO_KEEPALIVE_FD" ]]; then
    exec {NIRILAND_SUDO_KEEPALIVE_FD}>&- 2>/dev/null || true
    NIRILAND_SUDO_KEEPALIVE_FD=""
  fi
}

niriland_sudo_session_start() {
  local invalidate_on_stop="${1:-false}"
  local interval="${NIRILAND_SUDO_KEEPALIVE_INTERVAL:-60}"
  local signal_dir
  local signal_fd
  local signal_pipe

  case "$invalidate_on_stop" in
    true|false)
      ;;
    *)
      niriland_die "invalidate_on_stop must be true or false" || return 1
      ;;
  esac

  if [[ ! "$interval" =~ ^[0-9]+([.][0-9]+)?$ \
    || "$interval" =~ ^0*([.]0*)?$ ]]; then
    niriland_die "sudo keepalive interval must be a positive number" || return 1
  fi

  if [[ -n "$NIRILAND_SUDO_KEEPALIVE_PID" ]] \
    && kill -0 "$NIRILAND_SUDO_KEEPALIVE_PID" 2>/dev/null; then
    if [[ "$invalidate_on_stop" == "true" ]]; then
      NIRILAND_SUDO_INVALIDATE_ON_STOP=true
    fi
    return 0
  fi

  command -v sudo >/dev/null 2>&1 \
    || niriland_die "Missing required command: sudo" \
    || return 1
  sudo -v || niriland_die "sudo authentication failed" || return 1

  niriland_sudo_session_close_signal_fd
  signal_dir="$(mktemp -d "${TMPDIR:-/tmp}/niriland-sudo.XXXXXX")" \
    || niriland_die "Could not create sudo keepalive signal directory" \
    || return 1
  signal_pipe="$signal_dir/stop"
  if ! mkfifo -- "$signal_pipe"; then
    rm -rf -- "$signal_dir"
    niriland_die "Could not create sudo keepalive signal pipe" || return 1
  fi
  if ! exec {signal_fd}<>"$signal_pipe"; then
    rm -rf -- "$signal_dir"
    niriland_die "Could not open sudo keepalive signal pipe" || return 1
  fi
  rm -rf -- "$signal_dir"

  NIRILAND_SUDO_KEEPALIVE_FD="$signal_fd"
  NIRILAND_SUDO_INVALIDATE_ON_STOP="$invalidate_on_stop"
  (
    while true; do
      if IFS= read -r -t "$interval" -u "$signal_fd"; then
        exit 0
      fi
      sudo -n true >/dev/null 2>&1 || exit 0
    done
  ) &
  NIRILAND_SUDO_KEEPALIVE_PID=$!
}

niriland_sudo_session_stop() {
  if [[ -n "$NIRILAND_SUDO_KEEPALIVE_PID" ]]; then
    if [[ -n "$NIRILAND_SUDO_KEEPALIVE_FD" ]]; then
      printf '\n' >&"$NIRILAND_SUDO_KEEPALIVE_FD" || true
    fi
    wait "$NIRILAND_SUDO_KEEPALIVE_PID" 2>/dev/null || true
    NIRILAND_SUDO_KEEPALIVE_PID=""
  fi
  niriland_sudo_session_close_signal_fd

  if [[ "$NIRILAND_SUDO_INVALIDATE_ON_STOP" == "true" ]] \
    && command -v sudo >/dev/null 2>&1; then
    sudo -k >/dev/null 2>&1 || true
  fi
  NIRILAND_SUDO_INVALIDATE_ON_STOP=false
}
