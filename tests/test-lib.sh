#!/usr/bin/env bash

set -euo pipefail

# This output is consumed by test scripts after sourcing this helper.
# shellcheck disable=SC2034
TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_COUNT=0

fail() {
  printf 'not ok - %s\n' "$*" >&2
  exit 1
}

pass() {
  TEST_COUNT=$((TEST_COUNT + 1))
  printf 'ok %d - %s\n' "$TEST_COUNT" "$1"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local description="$3"

  [[ "$haystack" == *"$needle"* ]] || fail "$description (missing: $needle)"
}

assert_not_exists() {
  local path="$1"
  local description="$2"

  [[ ! -e "$path" && ! -L "$path" ]] || fail "$description (exists: $path)"
}

assert_command_fails() {
  local description="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    fail "$description (command unexpectedly succeeded)"
  fi
}
