#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"

test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
test_home="$test_dir/home"
test_state="$test_dir/state"
mkdir -p "$test_home/.local/bin/niriland"
printf 'old copy\n' > "$test_home/.local/bin/niriland/old-tool"
# These lines model literal shell configuration written to a profile.
# shellcheck disable=SC2016
printf '%s\n' \
  '# niriland-path' \
  'export PATH="$HOME/.local/bin:$HOME/.local/bin/niriland:$PATH"' \
  > "$test_home/.profile"
# shellcheck disable=SC2016
printf '%s\n' \
  '# niriland-path' \
  'export PATH="$HOME/.local/bin:$HOME/.local/bin/niriland:$PATH"' \
  > "$test_home/zprofile-target"
chmod 600 "$test_home/zprofile-target"
ln -s zprofile-target "$test_home/.zprofile"

HOME="$test_home" XDG_STATE_HOME="$test_state" \
  bash "$TEST_ROOT/installer/steps/50-setup-tools" >/dev/null

[[ -L "$test_home/.local/bin/niriland" ]] \
  || fail "public niriland command was not linked"
[[ "$(readlink -f -- "$test_home/.local/bin/niriland")" == "$TEST_ROOT/bin/niriland" ]] \
  || fail "public niriland command points at the wrong source"
pass "tool setup links the public command"

printf 'profile=desktop\n' > "$test_dir/machine.local.conf"
linked_plan="$(
  HOME="$test_home" \
  NIRILAND_MACHINE_CONFIG="$test_dir/machine.local.conf" \
  NIRILAND_STATE_HOME="$test_state/runtime" \
    "$test_home/.local/bin/niriland" plan
)"
assert_contains "$linked_plan" 'Profile: desktop' \
  "linked niriland command did not resolve its repository"
pass "linked public command resolves repository-relative libraries"

[[ -L "$test_home/.local/bin/niriland-pkg" ]] \
  || fail "package helper was not linked"
[[ "$(readlink -f -- "$test_home/.local/bin/niriland-pkg")" == "$TEST_ROOT/bin/niriland-pkg" ]] \
  || fail "package helper points at the wrong source"
pass "tool setup links public helpers"

old_backup="$(find "$test_state/niriland/backups" -type f -path '*/niriland/old-tool' -print -quit)"
[[ -n "$old_backup" ]] || fail "old copied tool directory was not backed up"
[[ "$(<"$old_backup")" == "old copy" ]] \
  || fail "old copied tool backup has unexpected content"
pass "tool setup backs up the old copied tool directory"

profile_content="$(<"$test_home/.profile")"
# The assertion checks a literal shell expression.
# shellcheck disable=SC2016
assert_contains "$profile_content" 'export PATH="$HOME/.local/bin:$PATH"' \
  "profile did not receive the flat tool path"
[[ "$profile_content" != *'.local/bin/niriland:'* ]] \
  || fail "profile retained the removed nested tool path"
pass "tool setup migrates the PATH block"

[[ -L "$test_home/.zprofile" ]] \
  || fail "profile update replaced an existing symlink"
[[ "$(stat -c '%a' "$test_home/zprofile-target")" == "600" ]] \
  || fail "profile update changed the target mode"
# The assertion checks a literal shell expression.
# shellcheck disable=SC2016
assert_contains "$(<"$test_home/zprofile-target")" \
  'export PATH="$HOME/.local/bin:$PATH"' \
  "symlinked profile target did not receive the flat tool path"
pass "tool setup preserves profile symlinks and modes"

fake_checkout="$test_dir/fake-checkout"
mkdir -p "$fake_checkout/installer/steps" "$fake_checkout/installer/lib"
: > "$fake_checkout/installer/install"
printf 'touch %q\n' "$test_dir/untrusted-common-sourced" \
  > "$fake_checkout/installer/lib/common.sh"
(
  cd "$fake_checkout"
  HOME="$test_home" \
    "$test_home/.local/bin/niriland-sync-base-config" --list >/dev/null
)
assert_not_exists "$test_dir/untrusted-common-sourced" \
  "global helper sourced installer code from the current directory"
pass "global helpers resolve their owning repository instead of PWD"

HOME="$test_home" XDG_STATE_HOME="$test_state" \
  bash "$TEST_ROOT/installer/steps/50-setup-tools" >/dev/null
[[ "$(readlink -f -- "$test_home/.local/bin/niriland")" == "$TEST_ROOT/bin/niriland" ]] \
  || fail "second tool setup changed the public command target"
pass "tool setup is idempotent"

printf '1..%d\n' "$TEST_COUNT"
