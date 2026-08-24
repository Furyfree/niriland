#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"
# shellcheck source=bootstrap
source "$TEST_ROOT/bootstrap"

test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/desktop" "$test_dir/laptop"

printf '%s\n' '1' >"$test_dir/desktop-selection"
ensure_machine_config \
  "$test_dir/desktop" "$test_dir/desktop-selection" "$test_dir/desktop-output"
[[ "$(<"$test_dir/desktop/machine.local.conf")" == 'profile=desktop' ]] \
  || fail "desktop selection did not create the expected machine config"
pass "bootstrap creates the desktop machine selector"

printf '%s\n' '2' >"$test_dir/replacement-selection"
ensure_machine_config \
  "$test_dir/desktop" "$test_dir/replacement-selection" "$test_dir/replacement-output"
[[ "$(<"$test_dir/desktop/machine.local.conf")" == 'profile=desktop' ]] \
  || fail "existing machine config was replaced"
assert_not_exists "$test_dir/replacement-output" \
  "preserving a machine config must not open the selector"
pass "bootstrap preserves an existing machine selector"

printf '%s\n' 'invalid' 'laptop' >"$test_dir/laptop-selection"
ensure_machine_config \
  "$test_dir/laptop" "$test_dir/laptop-selection" "$test_dir/laptop-output"
[[ "$(<"$test_dir/laptop/machine.local.conf")" == 'profile=laptop' ]] \
  || fail "laptop selection did not create the expected machine config"
laptop_output="$(<"$test_dir/laptop-output")"
assert_contains "$laptop_output" 'Choose 1 (desktop) or 2 (laptop).' \
  "invalid profile selection must be explained"
pass "bootstrap retries invalid input and accepts the named laptop profile"

printf '%s\n' 'yes' >"$test_dir/confirm-yes"
confirm_legacy_install "$test_dir/confirm-yes" "$test_dir/confirm-yes-output" \
  || fail "explicit yes did not confirm installation"
pass "bootstrap accepts explicit installation confirmation"

: >"$test_dir/confirm-no"
assert_command_fails "default-negative confirmation must cancel installation" \
  confirm_legacy_install "$test_dir/confirm-no" "$test_dir/confirm-no-output"
pass "bootstrap defaults installation confirmation to no"

printf '1..%d\n' "$TEST_COUNT"
