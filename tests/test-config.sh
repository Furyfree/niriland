#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"
# shellcheck source=src/niriland/config.sh
source "$TEST_ROOT/src/niriland/config.sh"

test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/repo/profiles" "$test_dir/repo/packages"
touch \
  "$test_dir/repo/packages/base.packages" \
  "$test_dir/repo/packages/dev.packages" \
  "$test_dir/repo/packages/gaming.packages" \
  "$test_dir/repo/packages/desktop.packages"

printf '%s\n' 'profile=desktop' >"$test_dir/machine.conf"
printf '%s\n' 'package_sets=base,dev,gaming,desktop' \
  >"$test_dir/repo/profiles/desktop.conf"

niriland_resolve_machine "$test_dir/repo" "$test_dir/machine.conf"
[[ "$NIRILAND_PROFILE" == "desktop" ]] || fail "valid profile was not selected"
[[ "${NIRILAND_PACKAGE_SETS[*]}" == "base dev gaming desktop" ]] \
  || fail "valid package sets were not resolved"
pass "strict parsers resolve a valid machine profile"

printf '%s\n' 'unknown=value' >"$test_dir/unknown.conf"
assert_command_fails "unknown machine keys must fail" \
  niriland_parse_machine_config "$test_dir/unknown.conf"
pass "unknown machine keys are rejected"

printf '%s\n' 'profile=desktop' 'profile=laptop' >"$test_dir/duplicate.conf"
assert_command_fails "duplicate machine keys must fail" \
  niriland_parse_machine_config "$test_dir/duplicate.conf"
pass "duplicate machine keys are rejected"

marker="$test_dir/injection-ran"
# Literal command substitution is the malicious input under test.
# shellcheck disable=SC2016
printf 'profile=$(touch %s)\n' "$marker" >"$test_dir/injection.conf"
assert_command_fails "shell syntax must fail" \
  niriland_parse_machine_config "$test_dir/injection.conf"
assert_not_exists "$marker" "machine config must never execute shell syntax"
pass "machine config is parsed as data"

printf '%s\n' 'package_sets=base,base' >"$test_dir/repo/profiles/duplicate.conf"
assert_command_fails "duplicate package sets must fail" \
  niriland_parse_profile "$test_dir/repo" duplicate
pass "duplicate package sets are rejected"

for invalid_list in 'base,dev,' ',base,dev' 'base,,dev'; do
  printf 'package_sets=%s\n' "$invalid_list" \
    >"$test_dir/repo/profiles/invalid-list.conf"
  assert_command_fails "invalid package set list must fail: $invalid_list" \
    niriland_parse_profile "$test_dir/repo" invalid-list
done
pass "empty package-set entries are rejected"

printf '%s\n' 'package_sets=base,missing' >"$test_dir/repo/profiles/missing.conf"
assert_command_fails "missing manifests must fail" \
  niriland_parse_profile "$test_dir/repo" missing
pass "missing package manifests are rejected"

printf '%s\n' 'unknown=value' >"$test_dir/repo/profiles/unknown.conf"
assert_command_fails "unknown profile keys must fail" \
  niriland_parse_profile "$test_dir/repo" unknown
pass "unknown profile keys are rejected"

profile_marker="$test_dir/profile-injection-ran"
# shellcheck disable=SC2016
printf 'package_sets=base,$(touch %s)\n' "$profile_marker" \
  >"$test_dir/repo/profiles/injection.conf"
assert_command_fails "profile shell syntax must fail" \
  niriland_parse_profile "$test_dir/repo" injection
assert_not_exists "$profile_marker" "profile config must never execute shell syntax"
pass "profile config is parsed as data"

printf '1..%d\n' "$TEST_COUNT"
