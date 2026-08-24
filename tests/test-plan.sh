#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"

# shellcheck source=scripts/lib/plan
source "$TEST_ROOT/scripts/lib/plan"

for resource_id in \
  'profile:desktop' \
  'package-set:base' \
  'migration:2026-08-23-example' \
  'home:.config/niri/config.kdl'; do
  niriland_validate_resource_id "$resource_id" \
    || fail "valid resource ID was rejected: $resource_id"
done
pass "resource IDs accept documented stable forms"

for resource_id in 'Home:desktop' 'home:' 'home:.' 'home:/etc/niri/config.kdl'; do
  assert_command_fails "invalid resource ID was accepted: $resource_id" \
    niriland_validate_resource_id "$resource_id"
done
pass "resource IDs reject malformed and absolute forms"

test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
printf '%s\n' 'profile=desktop' >"$test_dir/machine.conf"

plan_output="$(
  NIRILAND_MACHINE_CONFIG="$test_dir/machine.conf" \
  NIRILAND_STATE_HOME="$test_dir/state" \
    "$TEST_ROOT/niriland" plan
)"
assert_contains "$plan_output" 'Profile: desktop' "plan must show selected profile"
assert_contains "$plan_output" 'SELECT   profile:desktop' "plan must emit stable profile ID"
assert_contains "$plan_output" 'DEFER    package-set:base' "plan must emit package set IDs"
assert_contains "$plan_output" 'No files, packages, services, or state were changed.' \
  "plan must state its read-only boundary"
assert_not_exists "$test_dir/state" "plan must not create state"
pass "plan resolves profile without creating state"

prune_output="$(
  NIRILAND_MACHINE_CONFIG="$test_dir/machine.conf" \
  NIRILAND_STATE_HOME="$test_dir/state" \
    "$TEST_ROOT/niriland" plan --prune
)"
assert_contains "$prune_output" 'Prune: true' "prune plan must be explicit"
assert_contains "$prune_output" 'package-prune:untracked' \
  "Phase 1 must defer rather than execute prune"
assert_not_exists "$test_dir/state" "prune plan must not create state"
pass "prune planning remains read-only and deferred"

status_output="$(
  NIRILAND_MACHINE_CONFIG="$test_dir/machine.conf" \
  NIRILAND_STATE_HOME="$test_dir/state" \
    "$TEST_ROOT/niriland" status
)"
assert_contains "$status_output" 'Package sets: base,dev,gaming,desktop' \
  "status must show composed package sets"
assert_contains "$status_output" '(not created)' "status must not create state"
pass "status reports Phase 1 foundations"

for invocation in 'apply' 'apply --prune' 'update' 'postinstall'; do
  read -r -a args <<<"$invocation"
  if env NIRILAND_MACHINE_CONFIG="$test_dir/machine.conf" \
    "$TEST_ROOT/niriland" "${args[@]}" >/dev/null 2>&1; then
    fail "$invocation unexpectedly succeeded"
  else
    command_status=$?
  fi
  [[ $command_status -eq 2 ]] \
    || fail "$invocation exited $command_status instead of 2"
done
pass "mutating commands are explicitly disabled"

printf '1..%d\n' "$TEST_COUNT"
