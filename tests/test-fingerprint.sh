#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"

test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT
fake_bin="$test_dir/bin"
command_log="$test_dir/commands.log"
mkdir -p "$fake_bin"
: >"$command_log"

for command_name in sudo pacman fprintd-list fprintd-enroll fprintd-verify; do
  # The generated fixture must expand this variable when the fake command runs.
  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s" >>"$NIRILAND_COMMAND_LOG"\n' \
    "$command_name" >"$fake_bin/$command_name"
  chmod +x "$fake_bin/$command_name"
done

status_output="$(
  PATH="$fake_bin:$PATH" NIRILAND_COMMAND_LOG="$command_log" \
    "$TEST_ROOT/bin/niriland-setup-fingerprint" status
)"
assert_contains "$status_output" 'Fingerprint mutation is disabled.' \
  "fingerprint status did not explain the disabled workflow"
pass "fingerprint status is read-only and explains the replacement"

for operation in setup --remove; do
  assert_command_fails "fingerprint $operation must remain disabled" \
    env PATH="$fake_bin:$PATH" NIRILAND_COMMAND_LOG="$command_log" \
      "$TEST_ROOT/bin/niriland-setup-fingerprint" "$operation"
done
pass "fingerprint setup and removal refuse mutation"

[[ ! -s "$command_log" ]] \
  || fail "disabled fingerprint helper invoked a mutating external command"
pass "fingerprint compatibility command invokes no system tools"

printf '1..%d\n' "$TEST_COUNT"
