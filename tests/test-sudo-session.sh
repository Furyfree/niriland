#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=tests/test-lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-lib.sh"
# shellcheck source=scripts/lib/sudo-session
source "$TEST_ROOT/scripts/lib/sudo-session"

test_dir="$(mktemp -d)"
trap 'niriland_sudo_session_stop; rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/bin"

cat >"$test_dir/bin/sudo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$FAKE_SUDO_LOG"
exit 0
EOF
chmod +x "$test_dir/bin/sudo"

export FAKE_SUDO_LOG="$test_dir/sudo.log"
export PATH="$test_dir/bin:$PATH"
export NIRILAND_SUDO_KEEPALIVE_INTERVAL=0.05

niriland_sudo_session_start true
sleep 0.15
niriland_sudo_session_stop

sudo_log="$(<"$FAKE_SUDO_LOG")"
assert_contains "$sudo_log" '-v' "sudo session must validate once"
assert_contains "$sudo_log" '-n true' "sudo session must refresh non-interactively"
assert_contains "$sudo_log" '-k' "long privileged flow must invalidate on stop"
[[ -z "$NIRILAND_SUDO_KEEPALIVE_PID" ]] || fail "sudo keepalive PID was not cleared"
pass "sudo keepalive uses validation, non-interactive refresh, and invalidation"

export NIRILAND_SUDO_KEEPALIVE_INTERVAL=60
niriland_sudo_session_start false
sleep 0.05
stop_started_at="$(date +%s%N)"
niriland_sudo_session_stop
stop_finished_at="$(date +%s%N)"
stop_elapsed_ns=$((stop_finished_at - stop_started_at))
(( stop_elapsed_ns < 2000000000 )) \
  || fail "sudo keepalive stop waited for the full sleep interval"
pass "sudo keepalive stops promptly during its sleep interval"

: >"$FAKE_SUDO_LOG"
niriland_sudo_session_start false
keepalive_pid="$NIRILAND_SUDO_KEEPALIVE_PID"
niriland_sudo_session_start true
[[ "$NIRILAND_SUDO_KEEPALIVE_PID" == "$keepalive_pid" ]] \
  || fail "starting an active sudo session created a second keepalive"
niriland_sudo_session_stop
sudo_log="$(<"$FAKE_SUDO_LOG")"
assert_contains "$sudo_log" '-k' \
  "an active sudo session must retain the stricter invalidation policy"
pass "sudo keepalive upgrades an active session to invalidate on stop"

export NIRILAND_SUDO_KEEPALIVE_INTERVAL=0
assert_command_fails "zero keepalive interval must fail" \
  niriland_sudo_session_start false
pass "sudo keepalive rejects an invalid interval"

printf '1..%d\n' "$TEST_COUNT"
